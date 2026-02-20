//
//  ViewController.swift
//  iQuiz
//
//  Created by nrml on 2/16/26.
//

import UIKit


struct Question {
    let text: String
    let answers: [String]
    let correctIndex: Int
}

struct Quiz {
    let title: String
    let questions: [Question]
}

enum QuizMode {
    case topics
    case question
    case answer
    case finished
}

class ViewController: UITableViewController {


    let quizzes: [Quiz] = [
        Quiz(title: "Mathematics", questions: [
            Question(text: "2 + 2 = ?", answers: ["3", "4", "5"], correctIndex: 1),
            Question(text: "5 × 3 = ?", answers: ["15", "10", "20"], correctIndex: 0)
        ]),
        Quiz(title: "Marvel Super Heroes", questions: [
            Question(text: "Who is Iron Man?",
                     answers: ["Tony Stark", "Steve Rogers", "Bruce Banner"],
                     correctIndex: 0),
            Question(text: "Thor is the god of?",
                     answers: ["Thunder", "Fire", "Water"],
                     correctIndex: 0)
        ]),
        Quiz(title: "Science", questions: [
            Question(text: "Water freezes at?",
                     answers: ["0°C", "100°C", "50°C"],
                     correctIndex: 0)
        ])
    ]


    var mode: QuizMode = .topics
    var quizIndex = 0
    var questionIndex = 0
    var selectedAnswer: Int?
    var score = 0
    var tipShown = false


    override func viewDidLoad() {
        super.viewDidLoad()
        title = "iQuiz"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Back",
            style: .plain,
            target: self,
            action: #selector(backPressed)
        )
        navigationItem.rightBarButtonItem = nil  // hidden initially

        setupGestures()
    }


    override func tableView(_ tableView: UITableView,
                            viewForHeaderInSection section: Int) -> UIView? {
        guard mode == .question || mode == .answer else { return nil }

        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .boldSystemFont(ofSize: 22)
        label.textColor = .label
        label.backgroundColor = .systemGroupedBackground
        label.text = "  " + quizzes[quizIndex].questions[questionIndex].text + "  "
        return label
    }

    override func tableView(_ tableView: UITableView,
                            heightForHeaderInSection section: Int) -> CGFloat {
        return (mode == .question || mode == .answer) ? UITableView.automaticDimension : 0
    }


    override func tableView(_ tableView: UITableView,
                            viewForFooterInSection section: Int) -> UIView? {
        switch mode {
        case .question:
            return makeFooterButton(title: "Submit", action: #selector(submitTapped))
        case .answer, .finished:
            return makeFooterButton(title: "Next", action: #selector(nextTapped))
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView,
                            heightForFooterInSection section: Int) -> CGFloat {
        switch mode {
        case .question, .answer, .finished: return 60
        default: return 0
        }
    }

    private func makeFooterButton(title: String, action: Selector) -> UIView {
        let container = UIView()
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        button.addTarget(self, action: action, for: .touchUpInside)
        return container
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        switch mode {
        case .topics:   return quizzes.count
        case .question: return quizzes[quizIndex].questions[questionIndex].answers.count
        case .answer:   return 2
        case .finished: return 2
        }
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)

        switch mode {

        case .topics:
            cell.textLabel?.text = quizzes[indexPath.row].title
            cell.accessoryType = .disclosureIndicator

        case .question:
            cell.textLabel?.text =
                quizzes[quizIndex].questions[questionIndex].answers[indexPath.row]
            cell.accessoryType = (indexPath.row == selectedAnswer) ? .checkmark : .none

        case .answer:
            let q = quizzes[quizIndex].questions[questionIndex]
            cell.selectionStyle = .none
            if indexPath.row == 0 {
                cell.textLabel?.text =
                    selectedAnswer == q.correctIndex ? "✅ Correct!" : "❌ Wrong!"
            } else {
                cell.textLabel?.text = "Correct answer: \(q.answers[q.correctIndex])"
            }

        case .finished:
            let total = quizzes[quizIndex].questions.count
            cell.selectionStyle = .none
            if indexPath.row == 0 {
                cell.textLabel?.text = "Score: \(score) of \(total)"
            } else {
                cell.textLabel?.text =
                    score == total       ? "Perfect!" :
                    score >= total / 2   ? "Almost!"  :
                                           "Better luck next time!"
            }
        }

        return cell
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch mode {
        case .topics:
            quizIndex = indexPath.row
            questionIndex = 0
            score = 0
            startQuiz()

        case .question:
            // Just select the answer — submission is via button or swipe
            selectedAnswer = indexPath.row
            tableView.reloadData()

        case .answer:
            goNext()

        case .finished:
            resetQuiz()
        }
    }


    @objc func submitTapped() {
        guard selectedAnswer != nil else {
            let alert = UIAlertController(
                title: "Pick an answer",
                message: "Please select an answer before submitting.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        showAnswer()
    }

    @objc func nextTapped() {
        switch mode {
        case .answer:   goNext()
        case .finished: resetQuiz()
        default: break
        }
    }


    func startQuiz() {
        mode = .question
        selectedAnswer = nil
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Back",
            style: .plain,
            target: self,
            action: #selector(backPressed)
        )
        title = quizzes[quizIndex].title
        showTipIfNeeded()
        tableView.reloadData()
    }

    func showAnswer() {
        let q = quizzes[quizIndex].questions[questionIndex]
        if selectedAnswer == q.correctIndex { score += 1 }
        mode = .answer
        tableView.reloadData()
    }

    func goNext() {
        questionIndex += 1
        if questionIndex < quizzes[quizIndex].questions.count {
            mode = .question
            selectedAnswer = nil
        } else {
            mode = .finished
        }
        tableView.reloadData()
    }

    func resetQuiz() {
        mode = .topics
        navigationItem.rightBarButtonItem = nil
        title = "iQuiz"
        tableView.reloadData()
    }
    
    @objc func backPressed() {
        score = 0
        resetQuiz()
    }

    func setupGestures() {
        let right = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        right.direction = .right
        tableView.addGestureRecognizer(right)

        let left = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        left.direction = .left
        tableView.addGestureRecognizer(left)
    }

    @objc func swiped(_ g: UISwipeGestureRecognizer) {
        if g.direction == .right {
            if mode == .question && selectedAnswer != nil {
                showAnswer()
            } else if mode == .answer {
                goNext()
            }
        } else if g.direction == .left {
            if mode != .topics {
                score = 0
                resetQuiz()
            }
        }
    }


    func showTipIfNeeded() {
        guard !tipShown else { return }
        tipShown = true
        let alert = UIAlertController(
            title: "How to Play",
            message: "Tap an answer to select it, then tap Submit.\n\nSwipe right to submit or advance.\nSwipe left to quit and return to topics.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Got it!", style: .default))
        present(alert, animated: true)
    }
}

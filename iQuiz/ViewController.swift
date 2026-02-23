//
//  ViewController.swift
//  iQuiz
//
// Created by nrml on 2/16/26.
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

struct QuizJSON: Codable {
    let title: String
    let desc: String
    let questions: [QuestionJSON]
}

struct QuestionJSON: Codable {
    let text: String
    let answer: String
    let answers: [String]
}


enum QuizMode {
    case topics
    case question
    case answer
    case finished
}

class ViewController: UITableViewController {


    let defaultQuizURL = "http://tednewardsandbox.site44.com/questions.json"
    let quizURLKey = "QuizURL"
    
    let refreshIntervalKey = "RefreshInterval"
    var refreshTimer: Timer?


    var quizzes: [Quiz] = [
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

        if UserDefaults.standard.string(forKey: quizURLKey) == nil {
            UserDefaults.standard.set(defaultQuizURL, forKey: quizURLKey)
        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Check Now",
            style: .plain,
            target: self,
            action: #selector(checkNowTapped)
        )

        navigationItem.rightBarButtonItem = nil

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self,
                                 action: #selector(refreshPulled),
                                 for: .valueChanged)

        setupGestures()

        fetchQuizzes()
        
        if UserDefaults.standard.object(forKey: refreshIntervalKey) == nil {
            UserDefaults.standard.set(30.0, forKey: refreshIntervalKey)
        }

        startAutoRefresh()
    }

    func startAutoRefresh() {
        refreshTimer?.invalidate()

        let interval = UserDefaults.standard.double(forKey: refreshIntervalKey)
        guard interval > 0 else { return }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval,
                                            repeats: true) { [weak self] _ in
            self?.fetchQuizzes()
        }
    }

    func fetchQuizzes() {
        guard let urlString = UserDefaults.standard.string(forKey: quizURLKey),
              let url = URL(string: urlString) else { return }

        let task = URLSession.shared.dataTask(with: url) { data, _, error in

            if error != nil || data == nil {
                DispatchQueue.main.async {
                    self.refreshControl?.endRefreshing()
                    self.showNetworkError()
                }
                return
            }

            do {
                let decoded = try JSONDecoder().decode([QuizJSON].self, from: data!)

                let loaded = decoded.map { quiz in
                    Quiz(
                        title: quiz.title,
                        questions: quiz.questions.map {
                            Question(
                                text: $0.text,
                                answers: $0.answers,
                                correctIndex: Int($0.answer)! - 1
                            )
                        }
                    )
                }

                DispatchQueue.main.async {
                    self.quizzes = loaded
                    self.resetQuiz()
                    self.refreshControl?.endRefreshing()
                }

            } catch {
                DispatchQueue.main.async {
                    self.refreshControl?.endRefreshing()
                    self.showNetworkError()
                }
            }
        }

        task.resume()
        
        self.startAutoRefresh()
    }

    deinit {
        refreshTimer?.invalidate()
    }
    
    func showNetworkError() {
        let alert = UIAlertController(
            title: "Network Error",
            message: "Unable to load quizzes.\nUsing built-in quizzes instead.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    override func tableView(_ tableView: UITableView,
                            viewForHeaderInSection section: Int) -> UIView? {
        guard mode == .question || mode == .answer else { return nil }

        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .boldSystemFont(ofSize: 22)
        label.backgroundColor = .systemGroupedBackground
        label.text = "  " + quizzes[quizIndex].questions[questionIndex].text + "  "
        return label
    }

    override func tableView(_ tableView: UITableView,
                            heightForHeaderInSection section: Int) -> CGFloat {
        return (mode == .question || mode == .answer)
            ? UITableView.automaticDimension : 0
    }

    override func tableView(_ tableView: UITableView,
                            viewForFooterInSection section: Int) -> UIView? {
        switch mode {
        case .question:
            return makeFooterButton(title: "Submit",
                                    action: #selector(submitTapped))
        case .answer, .finished:
            return makeFooterButton(title: "Next",
                                    action: #selector(nextTapped))
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

    private func makeFooterButton(title: String,
                                  action: Selector) -> UIView {
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
                            cellForRowAt indexPath: IndexPath)
    -> UITableViewCell {

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)

        switch mode {

        case .topics:
            cell.textLabel?.text = quizzes[indexPath.row].title
            cell.accessoryType = .disclosureIndicator

        case .question:
            cell.textLabel?.text =
                quizzes[quizIndex].questions[questionIndex].answers[indexPath.row]
            cell.accessoryType =
                indexPath.row == selectedAnswer ? .checkmark : .none

        case .answer:
            let q = quizzes[quizIndex].questions[questionIndex]
            cell.selectionStyle = .none
            cell.textLabel?.text =
                indexPath.row == 0
                ? (selectedAnswer == q.correctIndex ? "✅ Correct!" : "❌ Wrong!")
                : "Correct answer: \(q.answers[q.correctIndex])"

        case .finished:
            let total = quizzes[quizIndex].questions.count
            cell.selectionStyle = .none
            cell.textLabel?.text =
                indexPath.row == 0
                ? "Score: \(score) of \(total)"
                : (score == total ? "Perfect!"
                   : score >= total / 2 ? "Almost!"
                   : "Better luck next time!")
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
            selectedAnswer = indexPath.row
            tableView.reloadData()

        case .answer:
            goNext()

        case .finished:
            resetQuiz()
        }
    }

    @objc func submitTapped() {
        guard selectedAnswer != nil else { return }
        showAnswer()
    }

    @objc func nextTapped() {
        if mode == .answer { goNext() }
        else if mode == .finished { resetQuiz() }
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
        let right = UISwipeGestureRecognizer(target: self,
                                             action: #selector(swiped))
        right.direction = .right
        tableView.addGestureRecognizer(right)

        let left = UISwipeGestureRecognizer(target: self,
                                            action: #selector(swiped))
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


    @objc func checkNowTapped() {
        fetchQuizzes()
    }

    @objc func refreshPulled() {
        fetchQuizzes()
    }

    func showTipIfNeeded() {
        guard !tipShown else { return }
        tipShown = true
        let alert = UIAlertController(
            title: "How to Play",
            message: "Tap an answer to select it, then tap Submit.\n\nSwipe right to submit or advance.\nSwipe left to quit.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Got it!", style: .default))
        present(alert, animated: true)
    }
}

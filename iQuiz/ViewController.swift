//
//  ViewController.swift
//  iQuiz
//
//  Created by nrml on 2/16/26.
//

import UIKit

struct Quiz {
    let title: String
    let description: String
    let iconName: String
}

class ViewController: UITableViewController {

    let quizzes = [
        Quiz(title: "Mathematics",
             description: "Test your math skills.",
             iconName: "math"),
        Quiz(title: "Marvel Super Heroes",
             description: "How well do you know Marvel?",
             iconName: "marvel"),
        Quiz(title: "Science",
             description: "Explore the world of science.",
             iconName: "science")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "iQuiz"

        navigationItem.rightBarButtonItem =
            UIBarButtonItem(title: "Settings",
                            style: .plain,
                            target: self,
                            action: #selector(showSettings))
    }

    @objc func showSettings() {
        let alert = UIAlertController(
            title: "Settings",
            message: "Settings go here",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return quizzes.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath)
        -> UITableViewCell {

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "QuizCell")
        let quiz = quizzes[indexPath.row]

        cell.textLabel?.text = quiz.title
        cell.detailTextLabel?.text = quiz.description
        cell.imageView?.image = UIImage(named: quiz.iconName)

        return cell
    }
}

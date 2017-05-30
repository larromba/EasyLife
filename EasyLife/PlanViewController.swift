//
//  PlanViewController.swift
//  EasyLife
//
//  Created by Lee Arromba on 12/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import UIKit

class PlanViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var tableHeaderView: TableHeaderView!
    
    var dataSource: PlanDataSource
    var badge: Badge
    
    required init?(coder aDecoder: NSCoder) {
        dataSource = PlanDataSource()
        badge = Badge()
        #if DEBUG
            //dataSource.itunesConnect()
        #endif
        super.init(coder: aDecoder)
        dataSource.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.isHidden = true
        tableView.applyDefaultStyleFix()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNotifications()
        dataSource.load()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tearDownNotifications()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? ItemDetailViewController else {
            return
        }
        if let item = sender as? TodoItem {
            vc.item = item
        }
    }
    
    // MARK: - private
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterForeground(_:)), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    private func tearDownNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    // MARK: - action
    
    @IBAction private func addButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "openEventDetailViewController", sender: nil)
    }
    
    @objc private func applicationDidEnterForeground(_ notification: Notification) {
        dataSource.load()
    }
}

// MARK: - UITableViewDelegate

extension PlanViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = dataSource.sections[indexPath.section][indexPath.row]
        performSegue(withIdentifier: "openEventDetailViewController", sender: item)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dataSource.title(forSection: section)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete".localized, handler: { [weak self] (action: UITableViewRowAction, path: IndexPath) in
            self?.dataSource.delete(at: indexPath)
        })
        delete.backgroundColor = UIColor.lightRed
        let done = UITableViewRowAction(style: .normal, title: "Done".localized, handler: { [weak self] (action: UITableViewRowAction, path: IndexPath) in
            self?.dataSource.done(at: indexPath)
        })
        done.backgroundColor = UIColor.lightGreen
        switch indexPath.section {
        case 1:
            let later = UITableViewRowAction(style: .normal, title: "Later".localized, handler: { [weak self] (action: UITableViewRowAction, path: IndexPath) in
                self?.dataSource.later(at: indexPath)
            })
            return [done, delete, later]
        default:
            return [done, delete]
        }
    }
}

// MARK: - UITableViewDataSource

extension PlanViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.sections[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = dataSource.sections[indexPath.section][indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlanCell", for: indexPath) as! PlanCell
        cell.recurringImageView.isHidden = (item.repeatState == nil || item.repeatState == RepeatState.none)
        if item.name == nil || item.name!.characters.count == 0 {
            cell.titleLabel.text = "[no name]".localized
            cell.titleLabel.textColor = UIColor.appleGrey
            return cell
        }
        cell.titleLabel.text = item.name
        switch indexPath.section {
        case 0:
            cell.titleLabel.textColor = UIColor.lightRed
        case 1:
            cell.titleLabel.textColor = UIColor.black
        default:
            cell.titleLabel.textColor = UIColor.appleGrey
        }
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.sections.count
    }
}

// MARK: - PlanDataSourceDelegate

extension PlanViewController: PlanDataSourceDelegate {
    func dataSorceDidLoad(_ dataSource: PlanDataSource) {
        tableHeaderView.isHidden = !dataSource.isDoneForNow
        tableView.isHidden = dataSource.isDoneTotally
        tableView.reloadData()
        badge.number = (dataSource.totalMissed + dataSource.totalToday)
    }
}

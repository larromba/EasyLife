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
    @IBOutlet weak var archiveButton: UIBarButtonItem!
    @IBOutlet weak var projectsButton: UIBarButtonItem!
    @IBOutlet weak var tableHeaderView: TableHeaderView!
    @IBOutlet weak var appVersionLabel: UILabel!

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
        tableView.applyDefaultStyleFix()
        tableHeaderView.setupWithHeight(tableView.bounds.size.height * 0.3)
        appVersionLabel.text = Bundle.appVersion()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNotifications()
        tableHeaderView.startAnimation()
        dataSource.load()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tableHeaderView.stopAnimation()
        tearDownNotifications()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ItemDetailViewController, let item = sender as? TodoItem {
            vc.dataSource.item = item
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
        return dataSource.title(for: section)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let item = dataSource.item(at: indexPath) else {
            log("epic fail")
            return [] // shouldnt happen
        }

        let delete = UITableViewRowAction(style: .destructive, title: "Delete".localized, handler: { [weak self] (action: UITableViewRowAction, path: IndexPath) in
            self?.dataSource.delete(at: indexPath)
        })
        let done = UITableViewRowAction(style: .normal, title: "Done".localized, handler: { [weak self] (action: UITableViewRowAction, path: IndexPath) in
            self?.dataSource.done(at: indexPath)
        })
        let split = UITableViewRowAction(style: .normal, title: "Split".localized, handler: { [weak self] (action: UITableViewRowAction, path: IndexPath) in
            self?.dataSource.split(at: indexPath)
        })
        let later = UITableViewRowAction(style: .normal, title: "Later".localized, handler: { [weak self] (action: UITableViewRowAction, path: IndexPath) in
            self?.dataSource.later(at: indexPath)
        })

        delete.backgroundColor = .lightRed
        done.backgroundColor = .lightGreen
        split.backgroundColor = .appleGrey

        var actions = [UITableViewRowAction]()
        if (item.blockedBy?.count ?? 0) == 0 {
            actions += [done]
        }
        actions += [delete]

        switch indexPath.section {
        case 0:
            if item.repeatState != RepeatState.none {
                actions += [split]
            }
        case 1:
            if item.repeatState == RepeatState.none {
                actions += [later]
            } else {
                actions += [later, split]
            }
        case 2:
            break
        default:
            log("unhandled switch")
            return []
        }

        return actions
    }
}

// MARK: - UITableViewDataSource

extension PlanViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.section(at: section)?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = dataSource.item(at: indexPath) else {
            log("epic fail")
            return UITableViewCell() // shouldnt happen
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlanCell", for: indexPath) as! PlanCell
        cell.indexPath = indexPath
        cell.item = item
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.sections.count
    }
}

// MARK: - DataSourceDelegate

extension PlanViewController: TableDataSourceDelegate {
    func dataSorceDidLoad<T: TableDataSource>(_ dataSource: T) {
        guard let dataSource = dataSource as? PlanDataSource else {
            return
        }
        tableHeaderView.isHidden = !dataSource.isDoneForNow
        tableView.isHidden = dataSource.isDoneTotally
        tableView.reloadData()
        badge.number = (dataSource.totalMissed + dataSource.totalToday)
    }
}

// MARK: - UIScrollViewDelegate

extension PlanViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        UIView.animate(withDuration: 0.2) { 
            self.appVersionLabel.alpha = 0.0
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        UIView.animate(withDuration: 0.4) {
            self.appVersionLabel.alpha = 1.0
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.contentOffset.y < 0, tableHeaderView.bounds.height > 0 else {
            return
        }
        let height = tableHeaderView.bounds.height / 4
        tableHeaderView.alphaMultiplier = max(0.0, 1.0 - (fabs(scrollView.contentOffset.y) / height))
    }
}

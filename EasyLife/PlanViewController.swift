//
//  PlanViewController.swift
//  EasyLife
//
//  Created by Lee Arromba on 12/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import UIKit

class PlanViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var addButton: UIBarButtonItem!
    
    var dataSource: PlanDataSource
    
    required init?(coder aDecoder: NSCoder) {
        dataSource = PlanDataSource()
        super.init(coder: aDecoder)
        dataSource.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dataSource.load()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? ItemDetailViewController else {
            return
        }
        if let item = sender as? TodoItem {
            vc.item = item
        }
    }
    
    // MARK: - action
    
    @IBAction fileprivate func addButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "openEventDetailViewController", sender: nil)
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
        return dataSource.titleFor(section: section)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {//TODO:localise
        let delete = UITableViewRowAction(style: .destructive, title: "Delete", handler: { [weak self] (action: UITableViewRowAction, path: IndexPath) in
            self?.dataSource.delete(at: indexPath)
        })
        let done = UITableViewRowAction(style: .normal, title: "Done", handler: { [weak self] (action: UITableViewRowAction, path: IndexPath) in
            self?.dataSource.done(at: indexPath)
        })
        done.backgroundColor = UIColor.green
        switch indexPath.section {
        case 1:
            let later = UITableViewRowAction(style: .normal, title: "Later", handler: { [weak self] (action: UITableViewRowAction, path: IndexPath) in
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
        if item.name?.characters.count == 0 {
            cell.titleLabel.text = "[no name]" //TODO:localise
        } else {
            cell.titleLabel.text = item.name
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
        tableView.isHidden = (dataSource.total == 0)
        tableView.reloadData()
    }
}

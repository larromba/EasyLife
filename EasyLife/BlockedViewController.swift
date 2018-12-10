import UIKit
import Logging

class BlockedViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    var dataSource: BlockedDataSource

    required init?(coder aDecoder: NSCoder) {
        dataSource = BlockedDataSource()
        super.init(coder: aDecoder)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.applyDefaultStyleFix()
        dataSource.delegate = self
        dataSource.load()
    }
}

// MARK: - UITableViewDelegate

extension BlockedViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dataSource.toggle(indexPath)
    }
}

// MARK: - UITableViewDataSource

extension BlockedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.rowCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = dataSource.item(at: indexPath) else {
            log("epic fail")
            return UITableViewCell() // shouldn't happen
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlockedCell", for: indexPath) as! BlockedCell
        cell.item = item
        cell.isBlocked = dataSource.isBlocked(item)
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.sectionCount
    }
}

// MARK: - TableDataSource

extension BlockedViewController: TableDataSourceDelegate {
    func dataSorceDidLoad<T: TableDataSource>(_ dataSource: T) {
        tableView.reloadData()
    }
}

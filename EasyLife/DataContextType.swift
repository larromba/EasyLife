import Foundation

enum DataContextType {
    case main
    case background
    case child(_ context: DataContext)
}

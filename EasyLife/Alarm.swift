import AVFoundation
import Foundation

// sourcery: name = Alarm
protocol Alarming: Mockable {
    func start()
    func stop()
}

final class Alarm: Alarming {
    let audioPlayer: AVAudioPlayer!

    init() {
        let url = Bundle.main.url(forResource: "alarm", withExtension: "aif")
        audioPlayer = try? AVAudioPlayer(contentsOf: url!)
        audioPlayer.numberOfLoops =  -1
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
    }

    func start() {
        audioPlayer.play()
    }

    func stop() {
        audioPlayer.stop()
    }
}

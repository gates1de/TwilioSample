//
//  ViewController.swift
//  TwilioSample
//
//  Created by Yu Kadowaki on 2018/06/16.
//  Copyright © 2018 gates1de. All rights reserved.
//

import UIKit
import TwilioVideo

class ViewController: UIViewController {

    private var room: TVIRoom?

    private var camera: TVICameraCapturer?

    private var localAudioTrack = TVILocalAudioTrack()

    private var localVideoTrack: TVILocalVideoTrack?

    private var remoteParticipant: TVIRemoteParticipant?


    @IBOutlet fileprivate weak var localView: UIView!

    @IBOutlet fileprivate weak var remoteView: UIView!


    @IBAction func didTapJoinRoomButton(_ sender: UIButton) {
        // NOTE: Token includes '"', so remove '"'
        guard let fetchedToken = try? TokenUtils.fetchToken(), let token = fetchedToken?.replacingOccurrences(of: "\"", with: "") else {
            return
        }

        self.showLocalView()

        let connectOptions = TVIConnectOptions.init(token: token) { builder in
            if let localAudioTrack = self.localAudioTrack {
                builder.audioTracks = [localAudioTrack]
            }

            if let localVideoTrack = self.localVideoTrack {
                builder.videoTracks = [localVideoTrack]
            }

            builder.roomName = "test_room"
        }

        self.room = TwilioVideo.connect(with: connectOptions, delegate: self)
    }


    override func viewDidLoad() {
        super.viewDidLoad()
    }

    fileprivate func showLocalView() {
        if let camera = TVICameraCapturer(source: .frontCamera),
            let videoTrack = TVILocalVideoTrack(capturer: camera) {

            // TVIVideoView is a TVIVideoRenderer and can be added to any TVIVideoTrack.
            let renderer = TVIVideoView(frame: self.localView.bounds)

            // Add renderer to the video track
            videoTrack.addRenderer(renderer)

            self.localVideoTrack = videoTrack
            self.camera = camera
            self.localView.addSubview(renderer)
        } else {
            print("Couldn't create TVICameraCapturer or TVILocalVideoTrack")
        }
    }
}

extension ViewController: TVIRoomDelegate {

    func didConnect(to room: TVIRoom) {
        if let localParticipant = room.localParticipant {
            print("Local identity \(localParticipant.identity)")
            self.showLocalView()
        }

        if (room.remoteParticipants.count > 0) {
            self.remoteParticipant = room.remoteParticipants.first
            self.remoteParticipant?.delegate = self
        }

        print("Number of connected Participants \(room.remoteParticipants.count)")
    }

    func room(_ room: TVIRoom, didFailToConnectWithError error: Error) {
        print("Failed to connect: \(error)")
    }

    func room(_ room: TVIRoom, participantDidConnect participant: TVIRemoteParticipant) {
        print ("Participant \(participant.identity) has joined Room \(room.name)")
        self.remoteParticipant = participant
        self.remoteParticipant?.delegate = self
    }

    func room(_ room: TVIRoom, participantDidDisconnect participant: TVIRemoteParticipant) {
        print ("Participant \(participant.identity) has left Room \(room.name)")
    }

}

extension ViewController: TVIRemoteParticipantDelegate {

    func videoView(_ view: TVIVideoView, videoDimensionsDidChange dimensions: CMVideoDimensions) {
        print("The dimensions of the video track changed to: \(dimensions.width)x\(dimensions.height)")
        self.view.setNeedsLayout()
    }

    func subscribed(to videoTrack: TVIRemoteVideoTrack, publication: TVIRemoteVideoTrackPublication, for participant: TVIRemoteParticipant) {
        print("subscribed \(participant.identity)")

        if let _ = self.remoteParticipant {
            if let remoteVideoView = TVIVideoView(frame: self.remoteView.bounds, delegate: self) {
                videoTrack.addRenderer(remoteVideoView)
                self.remoteView.addSubview(remoteVideoView)
            }
        }
    }
}

extension ViewController: TVIVideoViewDelegate {

}

struct TokenUtils {
    static func fetchToken() throws -> String? {
        guard let tokenUrlString = ProcessInfo.processInfo.environment["TwilioTokenUrl"] else {
            print("Cannot get tokenUrl!")
            return nil
        }

        let requestUrl: URL = URL(string: tokenUrlString)!
        do {
            let data = try Data(contentsOf: requestUrl)
            return String.init(data: data, encoding: String.Encoding.utf8)
        } catch let error as NSError {
            print ("Invalid token url, error = \(error)")
            throw error
        }
    }
}

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

    private var localVideoView: TVIVideoView?

    private var localAudioTrack = TVILocalAudioTrack()

    private var localVideoTrack: TVILocalVideoTrack?

    private var remoteParticipant: TVIRemoteParticipant?

    private var remoteVideoView: TVIVideoView?

    @IBOutlet fileprivate weak var localView: UIView!

    @IBOutlet fileprivate weak var remoteView: UIView!

    private let supportedAudioCodecs: [TVIAudioCodec] = [
        TVIIsacCodec(),
        TVIOpusCodec(),
        TVIPcmaCodec(),
        TVIPcmuCodec(),
        TVIG722Codec()
    ]

    private let supportedVideoCodecs: [TVIVideoCodec] = [
        TVIVp8Codec(),
        TVIVp8Codec(simulcast: true),
        TVIH264Codec(),
        TVIVp9Codec()
    ]


    @IBAction func didTapJoinRoomButton(_ sender: UIButton) {
        // NOTE: Token includes '"', so remove '"'
        guard let fetchedToken = try? TokenUtils.fetchToken(), let token = fetchedToken?.replacingOccurrences(of: "\"", with: "") else {
            return
        }

        self.showLocalVideoView()

        let connectOptions = TVIConnectOptions.init(token: token) { builder in
            builder.audioTracks = self.localAudioTrack != nil ? [self.localAudioTrack!] : []
            builder.videoTracks = self.localVideoTrack != nil ? [self.localVideoTrack!] : []

            builder.preferredAudioCodecs = self.supportedAudioCodecs
            builder.preferredVideoCodecs = self.supportedVideoCodecs

            builder.roomName = "test_room"
        }

        self.room = TwilioVideo.connect(with: connectOptions, delegate: self)
    }


    override func viewDidLoad() {
        super.viewDidLoad()
    }

    fileprivate func showLocalVideoView() {
        if let camera = TVICameraCapturer(source: .frontCamera), let videoTrack = TVILocalVideoTrack(capturer: camera) {
            let localVideoView = TVIVideoView(frame: self.localView.bounds)
            self.localVideoView = localVideoView

            // Add renderer to the video track
            videoTrack.addRenderer(localVideoView)

            self.localVideoTrack = videoTrack
            self.camera = camera
            self.localView.addSubview(localVideoView)
        } else {
            print("Couldn't create TVICameraCapturer or TVILocalVideoTrack")
        }
    }

    fileprivate func dismissLocalVideoView() {
        self.localVideoView?.removeFromSuperview()
    }
}

extension ViewController: TVIRoomDelegate {

    func didConnect(to room: TVIRoom) {
        if (room.remoteParticipants.count > 0) {
            self.remoteParticipant = room.remoteParticipants.first
            self.remoteParticipant?.delegate = self
        }

        print("Number of connected Participants \(room.remoteParticipants.count)")
    }

    func room(_ room: TVIRoom, didDisconnectWithError error: Error?) {
        print("Disconnected with: \(error)")
        self.dismissLocalVideoView()
    }

    func room(_ room: TVIRoom, didFailToConnectWithError error: Error) {
        print("Failed to connect: \(error)")
        self.dismissLocalVideoView()
    }

    func room(_ room: TVIRoom, participantDidConnect participant: TVIRemoteParticipant) {
        print ("Participant \(participant.identity) has joined Room \(room.name)")

        guard let _ = self.remoteParticipant else {
            self.remoteParticipant = participant
            self.remoteParticipant?.delegate = self
            return
        }
    }

    func room(_ room: TVIRoom, participantDidDisconnect participant: TVIRemoteParticipant) {
        print ("Participant \(participant.identity) has left Room \(room.name)")
    }

}

extension ViewController: TVIRemoteParticipantDelegate {

    func subscribed(to videoTrack: TVIRemoteVideoTrack, publication: TVIRemoteVideoTrackPublication, for participant: TVIRemoteParticipant) {
        print("subscribed \(participant.identity)")

        if let _ = self.remoteParticipant {
            if let remoteVideoView = TVIVideoView(frame: self.remoteView.bounds, delegate: self) {
                self.remoteVideoView = remoteVideoView
                videoTrack.addRenderer(remoteVideoView)
                self.remoteView.addSubview(remoteVideoView)
            }
        }
    }

    func unsubscribed(from videoTrack: TVIRemoteVideoTrack, publication: TVIRemoteVideoTrackPublication, for participant: TVIRemoteParticipant) {
        if let _ = self.remoteParticipant, let remoteVideoView = self.remoteVideoView {
            videoTrack.removeRenderer(remoteVideoView)
            remoteVideoView.removeFromSuperview()
            self.remoteVideoView = nil
        }

        self.remoteParticipant = nil
    }
}

extension ViewController: TVIVideoViewDelegate {

    func videoView(_ view: TVIVideoView, videoDimensionsDidChange dimensions: CMVideoDimensions) {
        self.view.setNeedsLayout()
    }
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

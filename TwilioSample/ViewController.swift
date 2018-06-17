//
//  ViewController.swift
//  TwilioSample
//
//  Created by Yu Kadowaki on 2018/06/16.
//  Copyright © 2018 gates1de. All rights reserved.
//

import UIKit
import TwilioVoice

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // NOTE: Token includes '"', so remove '"'
        guard let fetchedToken = try? TokenUtils.fetchToken(), let token = fetchedToken?.replacingOccurrences(of: "\"", with: "") else {
            return
        }

        print("token = \(token)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

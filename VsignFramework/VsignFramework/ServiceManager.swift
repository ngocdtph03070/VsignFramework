//
//  ServiceManager.swift
//  Merchanics
//
//  Created by Anh Son Le on 9/6/16.
//  Copyright © 2016 Pham Hoa. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyDrop
import EVReflection

// MARK: - ServerRequest
class ServerRequest {
    init (isDownload: Bool = false, saveToURL: URL = URL.init(fileURLWithPath: ""), method: Alamofire.HTTPMethod, encoding: ParameterEncoding, path: String, header: [String: String]? = nil, parameters: [String: AnyObject]?, datas: [(Data, String, String)]?, responseType: ServerResponse.Type) {
        self.method = method
        self.encoding = encoding
        self.path = path
        self.urlString = ServiceManager.baseURL + path
        self.params = parameters
        self.datas = datas
        self.responseType = responseType.self
        self.header = header
        self.isDownload = isDownload
        self.fileURL = saveToURL
    }
    var method: Alamofire.HTTPMethod
    var encoding: ParameterEncoding
    var path: String
    var urlString: String
    var params: [String: AnyObject]?
    var datas: [(Data, String, String)]?
    var responseType: ServerResponse.Type
    var header: [String: String]?
    var isDownload: Bool
    var fileURL: URL
}

// MARK: - ServerResponse
class ServerResponse {
    required init(responseData: AnyObject) {
        self.responseData = responseData
    }
    var responseData: AnyObject
    var statusCode: Int? {
        get {
            if let dict = responseData as? [String: AnyObject] {
                return (dict["status"] as? NSNumber)?.intValue
            }
            return nil
        }
    }
    var message: String? {
        get {
            if let dict = responseData as? [String: AnyObject] {
                return dict["message"] as? String
            }
            return nil
        }
    }
    var data: AnyObject? {
        get {
            if let dict = responseData as? [String: AnyObject] {
                return dict["data"]
            }
            return nil
        }
    }
    var errorCode: Int? {
        get {
            if let dict = responseData as? [String: AnyObject] {
                return (dict["status"] as? NSNumber)?.intValue
            }
            return nil
        }
    }
    var link: String? {
        get {
            if let dict = responseData as? [String: AnyObject] {
                return dict["link"] as? String
            }
            return nil
        }
    }
}

public enum VsignClientEnvironment{
    case vmodev
    case vsign
    case customURL(String)
    var url:String{
        switch self {
        case .vmodev:
            return "http://demo.vmodev.com:8080/vsign"
        case .vsign:
            return "https://cms.ca.gov.vn:10443"
        case .customURL(let url):
            return url
        }
    }
}

public class VsignConfiguaration:NSObject{
    public static var environment = VsignClientEnvironment.vmodev
}

class ServiceManager: NSObject,URLSessionDelegate,URLSessionTaskDelegate {
    static var baseURL:String{
        return VsignConfiguaration.environment.url
    }
    static let sharedInstance = ServiceManager.init()
    static var manager:SessionManager!
    override init() {
        super.init()
        
        
        let hostname = URL(string:ServiceManager.baseURL)?.host ?? ""

        let serverTrustPolicies:[String : ServerTrustPolicy] = [
            hostname:ServerTrustPolicy.disableEvaluation
        ]
        
        let serverTrustPolicyManager = ServerTrustPolicyManager(policies: serverTrustPolicies )
       
        if ServiceManager.baseURL.contains("https://") == true{
            ServiceManager.manager = SessionManager(
                configuration: URLSessionConfiguration.default,
                serverTrustPolicyManager:serverTrustPolicyManager
            )
        }else{
            ServiceManager.manager = Alamofire.SessionManager.default
        }
        
        ServiceManager.manager.session.configuration.timeoutIntervalForRequest = 300//
        ServiceManager.manager.session.configuration.timeoutIntervalForResource = 300
        
    }
    
    class func execute(_ request: ServerRequest, inViewController: UIViewController? = nil, completionHandle:@escaping ((_ isSuccess: Bool, _ response: ServerResponse?) -> Void), failureHandle:((_ code: Int?,_ message: String?) -> Void)? = nil, animate: Bool, showErrorMessage: Bool = true, createRequestSuccess:((Request) -> Void)? = nil) {
        ServiceManager.sharedInstance.execute(request, inViewController: inViewController, completionHandle: completionHandle, failureHandle: failureHandle, animate: animate, showErrorMessage: showErrorMessage, createRequestSuccess: createRequestSuccess)
    }
    
    func execute(_ request: ServerRequest, inViewController: UIViewController? = nil, completionHandle:@escaping ((_ isSuccess: Bool, _ response: ServerResponse?) -> Void), failureHandle:((_ code: Int?,_  message: String?) -> Void)? = nil, animate: Bool, showErrorMessage: Bool = false, createRequestSuccess:((Request) -> Void)? = nil) {
        
        // handle when requests fail
        func failure(_ code: Int = -1, message: String? = nil) {
            failureHandle?(code, message)
            if (showErrorMessage) {
                Drop.down(message ?? "Something went wrong", state: .error, duration: 5, action: nil)
            } else {
                Drop.upAll()
            }
        }
        
        print("==============================================")
        print("API: \(request.urlString)")
        print("Parameters: \(request.params)")
        if !Reachability.isConnectedToNetwork() {
			Drop.down("Không có kết nối mạng.", state: .error, duration: 4, action: nil)
            completionHandle(false, nil)
            return
        }

//        if animate {
//            if let topVC = Utils.topViewController() {
//                topVC.showProgressHubAnimating()
//
//            }
//        }
//
//        func hideProgressHub() {
//            if animate {
//                if let topVC = Utils.topViewController() {
//                    topVC.hideProgressHub()
//                } else {
//                    NVActivityIndicatorPresenter.sharedInstance.stopAnimating(nil)
//                }
//            }
//        }

        if request.isDownload{
            
            let req = ServiceManager.manager.download(request.urlString,
                                         method: request.method,
                                         parameters: request.params,
                                         encoding: request.encoding,
                                         headers: request.header,
                                         to: { (url, response) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
                                            return (request.fileURL, .createIntermediateDirectories)
            }).responseData(completionHandler: { (downloadResponse) in
//                hideProgressHub()
                switch downloadResponse.result {
                case .success(let data):
                    print("==============================================")
                    print("API: ", request.urlString)
                    if let statusCode = downloadResponse.response?.statusCode {
                        do {
                            let responseObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
                            print("Response: ",responseObject)
                            let response = request.responseType.init(responseData: responseObject as AnyObject)
                            if statusCode == 200 {
                                completionHandle(true, response)
                                return
                            } else {
                                failure(response.errorCode ?? -1, message: response.message)
                                completionHandle(false, response)
                                return
                            }
                        } catch {
                            failure()
                            completionHandle(false, nil)
                            return
                        }
                    }
                    failure()
                    completionHandle(false, nil)
                    
                case .failure:
                    failure()
                    completionHandle(false, nil)
                }
            })
            createRequestSuccess?(req)
        } else if let datas = request.datas {
            do {
                let url = try URLRequest(url: request.urlString, method: request.method, headers: request.header)
              
                ServiceManager.manager.session.configuration.timeoutIntervalForRequest = 300//
                ServiceManager.manager.session.configuration.timeoutIntervalForResource = 300
                ServiceManager.manager.upload(multipartFormData: { (multipartFormData) in
                    for (data, key, mimeType) in datas {
                        multipartFormData.append(data, withName: key, fileName: "image.jpeg", mimeType: mimeType)
                    }
                    if let parameters = request.params {
                        for (key, value) in parameters {
                            if let data = "\(value)".data(using: String.Encoding.utf8) {
                                multipartFormData.append(data, withName: key)
                            }
                        }
                    }
                    }, with: url, encodingCompletion: { (encodingResult) in
                        switch encodingResult {
                        case .success(let upload, _, _):
                            let req = upload.response(completionHandler: { (uploadResponse) in
//                                hideProgressHub()
                                print("==============================================")
                                print("API: ", request.urlString)
                                if let statusCode = uploadResponse.response?.statusCode {
                            
                                    if uploadResponse.error == nil {
                                        if let data = uploadResponse.data {
                                            
                                            let response = request.responseType.init(responseData:data as AnyObject)
                                            if statusCode == 200 {
                                                completionHandle(true, response)
                                                return
                                            } else {
                                                failure(response.errorCode ?? -1, message: response.message)
                                                completionHandle(false, response)
                                                return
                                            }
                                        }
                                    }
                                }
                                failure()
                                completionHandle(false, nil)
                            })
                            createRequestSuccess?(req)
                        case .failure(let error):
                            print(error)
                            failure()
                            completionHandle(false, nil)
                        }
                })
            } catch {}
        } else {
            let req = ServiceManager.manager.request(request.urlString, method: request.method, parameters: request.params, encoding: request.encoding, headers: request.header)
            req.response(completionHandler: { (res) in
//                hideProgressHub()
                print("==============================================")
                print("API: ", request.urlString)
                if let statusCode = res.response?.statusCode {
                    if res.error == nil {
                        if let data = res.data {
                            do {
                                let responseObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
                                print("Response: ",responseObject)
                                let response = request.responseType.init(responseData: responseObject as AnyObject)
                                if statusCode == 200 {
                                    completionHandle(true, response)
                                    return
                                } else {
                                    failure(response.errorCode ?? -1, message: response.message)
                                    completionHandle(false, response)
                                    return
                                }
                            } catch {
                                failure()
                                completionHandle(false, nil)
                                return
                            }
                        }
                    }
                }
                failure()
                completionHandle(false, nil)
            })
            createRequestSuccess?(req)
        }
    }
}


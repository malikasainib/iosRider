//
//  HomeAPI.swift
//  Rider ridesharerates
//
//  Created by malika on 27/09/23.
//
import UIKit
import CoreLocation
import Alamofire
import GooglePlaces
import GoogleMaps
import SystemConfiguration
import Reachability
//MARK:- Web Api
extension HomeViewController {
    //MARK:- Get vehicle type api
    func getVechileTypeApi(){
        var finalPickUpLatTap = ""
        var finalPickUpLongTap = ""
        print("Current LAT===\(kCurrentLocaLat)")
        print("Current LAT===\(kCurrentLocaLong)")
        
        if locationPickUpEditStatus == false && locationDropUpEditStatus == true{
            print("pickup not tap")
            finalPickUpLatTap =   kCurrentLocaLat
            finalPickUpLongTap = kCurrentLocaLong
        }
        
        if locationPickUpEditStatus == true && locationDropUpEditStatus == true {
            print("pickup tap")
            finalPickUpLatTap =   kPickUpLatFinal
            finalPickUpLongTap = kPickUpLongFinal
        }
        
        
        print(finalPickUpLatTap)
        print(finalPickUpLongTap)
        
        let param : [String : Any] = ["pickup_lat" : finalPickUpLatTap,
                                      "pickup_long" : finalPickUpLongTap,
                                      "drop_lat" : kDropLat ,
                                      "drop_long" : kDropLong] as [String : Any]
        
        kCurrentLocaLatLongTap =   "\(finalPickUpLatTap)" + "," + "\(finalPickUpLongTap)"
        kDestinationLatLongTap =  "\(kDropLat)" + "," + "\(kDropLong)"
        self.routingLines(origin: kCurrentLocaLatLongTap ,destination: kDestinationLatLongTap)
        print(param)
        Indicator.shared.showProgressView(self.view)
        let urlString = "\(baseURL)vehicle-category"
        let url = URL.init(string: urlString)
        var headers: HTTPHeaders = [:]
        headers = ["Authorization" : "Bearer " + (UserDefaults.standard.value(forKey: "token") as? String ?? "")
        ]
        print(headers)
        print(param)
        AF.request(urlString, method: .post, parameters: param, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                print("responseString: \(response)")
                Indicator.shared.hideProgressView()
                switch (response.result) {
                case .success(let JSON):
                    print("JSON: \(JSON)")
                    let str =  "\(JSON)"
                    let dict = self.convertStringToDictionary(text: str)
                    print("Finally dict is here=======\(dict)")
                    if let detailsDict = dict as NSDictionary? {
                        print("Parse Data")
                        let msg = detailsDict["message"] as? String ?? "Something went wrong"
                        print(msg)
                        if (dict?["status"] as? Int ?? 0) == 1 {                        self.chooseRide_view.isHidden = true
                            let  data = (dict?["data"] as? [[String:AnyObject]] ?? [[:]])
                            print(data)
                            self.rideDistance = (dict?["distance"] as? String ?? "")
                            kDistanceInMiles = (dict?["distance"] as? String ?? "")
                            kFinalAmountMile = (dict?["amount"] as? String ?? "")
                            do{
                                let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                                self.getAllVechileData = try newJSONDecoder().decode(vechile.self, from: jsonData)
                                self.chooseVehicleList = chooseRideList.show
                                //   self.getNearbyDrivers()
                               
                                let next = self.storyboard!.instantiateViewController(withIdentifier: "vehiclecategoryViewID") as! vehiclecategoryView
                                next.allData = self.getAllVechileData
                                next.delegate = self
                                next.modalPresentationStyle = .overFullScreen
                                self.present(next, animated: true, completion: nil)
                                //  self.ride_tableView.reloadData()
                                //  print(self.getAllVechileData)
                            }catch{
                                print(error.localizedDescription)
                            }
                        }
                        else{
                            self.showAlert("Rider RideshareRates", message: "\(msg)")
                        }
                    }
                    //                    if let responseString = dict as? [String : AnyObject] ?? [:] {
                    //
                    //                    }
                    //                    let msg = responseString["message"] as? String ?? ""
                    //
                    
                    break;
                case .failure(let error):
                    print(error)
                    self.showAlert("Rider RideshareRates", message: "\(error.localizedDescription)")
                    break
                }
            }
       
    }
    
    func checkdevicetokenAPI(){
        Indicator.shared.showProgressView(self.view)
        self.conn.startConnectionWithPostType(getUrlString: "checkdevicetoken", params: ["":""], authRequired: true) { (value) in
            Indicator.shared.hideProgressView()
            if self.conn.responseCode == 1{
                print(value)
                // let device_type = (value["device_type"] as? String ?? "")
                let device_token = (value["device_token"] as? String ?? "")
                let deviceID =  UIDevice.current.identifierForVendor?.uuidString
                if device_token != deviceID{
                    
                    if Reachability.isConnectedToNetwork(){
                       
                        self.logO()
                    }else{
                      //  print("Internet Connection not Available!")
                        self.showAlert("Rider RideshareRates", message: "Internet connection appears to be offline")
                    }
                    
                }
            }
        }
    }
    
    //MARK:- after login clear token and move to signin screen
    func logO(){
        UserDefaults.standard.set(false, forKey: "isUserLoggedIn")
        UserDefaults.standard.synchronize()
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        let loginVc = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        self.navigationController?.setViewControllers([loginVc], animated: true)
    }
    
    //MARK:- ride now api
    func rideNowApi(){
        
        
        Indicator.shared.showProgressView(self.view)
        //        let firsLocation = CLLocation(latitude:kCurrentLocaLat.toDouble() ?? 0.0, longitude:kCurrentLocaLong.toDouble() ?? 0.0)
        //        let secondLocation = CLLocation(latitude: kDropLat.toDouble() ?? 0.0, longitude: kDropLong.toDouble() ?? 0.0)
        //        //        let distance = firsLocation.distance(from: secondLocation) / 1000
        //        //        let miles =     "\(String(format:"%.02f", distance))"
        //        let distance = firsLocation.distance(from: secondLocation) * 0.000621371
        //        print(distance)
        //        let roundedValue = round(distance * 10) / 10.0
        //        print(roundedValue)
        
//        let vehicleTypeIdInt : Int =  Int(vehicleTypeId) ?? 0
//        let vehicleTypeIdMinus =  vehicleTypeIdInt - 1
//        print(vehicleTypeIdMinus)
        
        var finalPickUpLatTap = ""
        var finalPickUpLongTap = ""
        
        
        if locationPickUpEditStatus == false && locationDropUpEditStatus == true{
            print("pickup not tap")
            finalPickUpLatTap =   kCurrentLocaLat
            finalPickUpLongTap = kCurrentLocaLong
        }
        if locationPickUpEditStatus == true && locationDropUpEditStatus == true {
            print("pickup tap")
            finalPickUpLatTap =   kPickUpLatFinal
            finalPickUpLongTap = kPickUpLongFinal
        }
        print(finalPickUpLatTap)
        print(finalPickUpLongTap)
        
        let param : [String : Any] = [  "pickup_lat" : finalPickUpLatTap ,
                                        "pickup_long": finalPickUpLongTap ,
                                        "pickup_adress" : self.pickUpAddress_lbl.text ?? "" ,
                                        "pikup_location" : self.pickUpAddress_lbl.text ?? "" ,
                                        "drop_address": kDropAddress,
                                        "drop_locatoin": kDropAddress,
                                        "drop_lat": kDropLat ,
                                        "drop_long": kDropLong,
                                        "distance": self.rideDistance ,
                                        "user_id" : NSUSERDEFAULT.value(forKey: kUserID) as? String ?? "",
                                        "amount": rideAmount ,
                                        "vehicle_type_id": "\(vehicleTypeId)",
                                        "txn_id" : txnID,
                                        "card_id": cardID
                                        //vehicleTypeId
                                        
        ] as [String : Any]
        print(param)
        let urlString = "\(baseURL)postRideToDriver"
        let url = URL.init(string: urlString)
        print(url)
        var headers: HTTPHeaders = [:]
        headers = ["Authorization" : "Bearer " + (UserDefaults.standard.value(forKey: "token") as? String ?? "")
        ]
        print(headers)
        
        AF.request(urlString, method: .post, parameters: param, encoding: URLEncoding.default, headers: headers)
        
            .responseString { response in
                print("responseString: \(response)")
                Indicator.shared.hideProgressView()
                switch (response.result) {
                case .success(let JSON):
                    print("JSON: \(JSON)")
                    let str =  "\(JSON)"
                    
                    let dict = self.convertStringToDictionary(text: str)
                    print("Finally dict is here=======\(dict)")
                    
                    if let detailsDict = dict as NSDictionary? {
                        print("Parse Data")
                        let msg = detailsDict["message"] as? String ?? ""
                        print(msg)
                        if (detailsDict["status"] as? Int ?? 0) == 1 {
                            let data = (detailsDict["ride_detail"] as? [String:Any] ?? [:])
                            kRideId = "\((data["ride_id"] as? Int ?? 0))"
                            kVehicle_no = "\((data["vehicle_no"] as? String ?? ""))"
                            kPaymentRideId = "\((data["ride_id"] as? Int ?? 0))"
                            kPaymentRideAmount = "\((data["amount"] as? String ?? ""))"
                            kPaymentDriverName = "\((data["name"] as? String ?? ""))"
                            //  self.showToast(message: "\(msg)")
                            self.chooseRide_view.isHidden = true
                            self.acceptRejectStatus(rideId: kRideId)
                            self.ride_tableView.reloadData()
                        }
                        else{
                            self.showAlert("Rider RideshareRates", message: "\(msg)")
                        }
                    }
                    break;
                case .failure(let error):
                    print(error)
                    self.showAlert("Rider RideshareRates", message: "\(error.localizedDescription)")
                    break
                }
            }
    }
    
    //MARK:- api for profile data get
    func getProfileDataApi() {
        Indicator.shared.showProgressView(self.view)
        self.conn.startConnectionWithGetTypeWithParam(getUrlString: "get_profile",authRequired: true) { (value) in
            print("Profile Data Api  \(value)")
            Indicator.shared.hideProgressView()
            let msg = (value["message"] as? String ?? "")
            if self.conn.responseCode == 1{
                if (value["status"] as? Int ?? 0) == 1{
                    let data = (value["data"] as? [String:AnyObject] ?? [:])
                    do{
                        let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                        self.profileDetails = try newJSONDecoder().decode(ProfileData.self, from: jsonData)
                        NSUSERDEFAULT.set((self.profileDetails?.last_name ?? ""), forKey: kName)
                        NSUSERDEFAULT.set((self.profileDetails?.email ?? ""), forKey: kEmail)
                        NSUSERDEFAULT.set((self.profileDetails?.profilePic ?? ""), forKey: kProfilePic)
                    }catch{
                        print(error.localizedDescription)
                    }
                }
                else{
                    self.showAlert("Rider RideshareRates", message: msg)
                }
            }
            else{
                guard let stat = value["Error"] as? String, stat == "ok" else {
                    return
                }
            }
        }
    }
    //MARK:- get api to find nearby  drivers
    func getNearbyDrivers(){
        let lat = NSUSERDEFAULT.value(forKey: kCurrentLat) as? String ?? ""
        let long = NSUSERDEFAULT.value(forKey: kCurrentLong) as? String ?? ""
        var param = [String : AnyObject]()
        param["lat"] = lat as AnyObject
        param["long"] = long as AnyObject
        //   print(param)
        DispatchQueue.main.async {
            NavigationManager.pushToLoginVC(from: self)
        }
        Indicator.shared.showProgressView(self.view)
        self.conn.startNewConnectionWithGetTypeWithParam(getUrlString: "nearby", authRequired : true, params: param) { (value) in
            print("Getting Nearby Data Api  \(value)")
            Indicator.shared.hideProgressView()
            if self.conn.responseCode == 1{
                let msg = (value["message"] as? String ?? "")
                if ((value["status"] as? Int ?? 0) == 1){
                    let data = (value["data"] as? [[String:AnyObject]] ?? [[:]])
                    var latLongDict = [String : Any]()
                    for items in data {
                        if var driverLat = items["latitude"] as? String {
                            print(driverLat)
                            latLongDict["latitude"] = driverLat
                        }
                        if var driverLong = items["longitude"] as? String {
                            print(driverLong)
                            latLongDict["longitude"] = driverLong
                        }
                        if let driverLong = items["name"] as? String {
                            print(driverLong)
                            latLongDict["name"] = driverLong
                        }
                        // name
                        //                        var driverLat = items["latitude"] as? String
                        //                        var driverLong = items["longitude"] as? String
                        //                        self.driverLatLNG =   "\(driverLat ?? "")" + "," + "\(driverLong ?? "")"
                        
                        self.nearByPlacesArray.append(latLongDict)
                        print(self.nearByPlacesArray)
                    }
                    for data in self.nearByPlacesArray{
                        let lat = data["latitude"] as? String ?? ""
                        let long = data["longitude"] as? String ?? ""
                        let name = data["name"] as? String ?? ""
                        
                        let latDouble = lat.toDouble()
                        let longDouble = long.toDouble()
                        //
                        var location = CLLocationCoordinate2D(latitude:latDouble!, longitude:longDouble!)
                        //                        print("location1: \(location)")
                        //                        self.marker.position = location
                        //                        self.marker.map = self.mapView
                        //                        self.marker.icon = UIImage(named: "car")
                        
                        
                        if kNotificationAction == "ACCEPTED" || kConfirmationAction == "ACCEPTED" || kNotificationAction == "START_RIDE" || kConfirmationAction == "START_RIDE"{
                            self.marker.map = nil
                            
                        }else{
                            
                            let puppyGif = UIImage(named: "car")
                            // var marker = GMSMarker()
                            let imageView = UIImageView(image: puppyGif)
                            imageView.frame = CGRect(x: 0, y: 0, width: 85, height: 60)
                            self.marker = GMSMarker(position: location)
                            self.marker.iconView = imageView
                            self.marker.title = name
                            self.marker.map = self.mapView
                            // self.marker.rotation = self.locationManager.location?.course ?? 0
                        }
                    }
                }else{
                    self.showAlert("Rider RideshareRates", message: msg)
                }
            }
            else{
                guard let stat = value["Error"] as? String, stat == "ok" else {
                    return
                }
            }
        }
    }
    func postFeedBackApi(ride_id: String, rating: String, comment :String ,driverId : String) {
        let param = ["ride_id": ride_id,"rating": rating  ,"comment" : comment ,"driver_id" : driverId]
        Indicator.shared.showProgressView(self.view)
        self.conn.startConnectionWithPostType(getUrlString: "give_feedback", params: param,authRequired: true) { (value) in
            //   print(value)
            let msg = (value["message"] as? String ?? "")
            Indicator.shared.hideProgressView()
            if self.conn.responseCode == 1{
                print(value)
                if (value["status"] as? Int ?? 0) == 1{
                    self.feedBackStatus = true
                    let data = (value["data"] as? [[String:AnyObject]] ?? [[:]])
                    self.chooseRide_view.isHidden = true
                    self.ride_tableView.isHidden = true
                    NSUSERDEFAULT.set(true, forKey: kFeedBack)
                    kNotificationAction = ""
                    kConfirmationAction = ""
                    self.chooseVehicleList = .hide
                    self.pickupBtn.isUserInteractionEnabled = true
                    self.dropBtn.isUserInteractionEnabled = true
                    self.pickupBtnCancel.isUserInteractionEnabled = true
                    self.dropBtnCancel.isUserInteractionEnabled = true
                    self.dropAddress_lbl.text = "Enter Drop Location"
                    kPaymentRideId = ""
                    kPaymentRideAmount = ""
                    self.mapView.clear()
                    // self.showAlert("Rider RideshareRates", message: msg)
                    
//                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "TipPopupVCID") as! TipPopupVC
//                    vc.delegate = self
//                    vc.modalPresentationStyle = .overFullScreen
//                    self.present(vc, animated: true, completion: nil)
                }
                else{
                    self.showAlert("Rider RideshareRates", message: msg)
                }
            }
            else{
                print("No Ride Available")
                guard var stat = value["Error"] as? String, stat == "ok" else {
                    //    self.showAlert("Rider RideshareRates", message: "\(String(describing: stat))")
                    return
                }
            }
        }
    }
    //MARK:- get ride status
    func getRideStatus(ride_id : String){
        let param = ["ride_id": ride_id]
        // print(param)
        Indicator.shared.showProgressView(self.view)
        self.conn.startConnectionWithPostType(getUrlString: "get_ride_status", params: param,authRequired: true) { (value) in
            print(value)
            Indicator.shared.hideProgressView()
            if self.conn.responseCode == 1{
                // print(value)
                let msg = (value["message"] as? String ?? "")
                if ((value["status"] as? Int ?? 0) == 1){
                    if let body = (value as? [String:Any])?["data"] as? [String:Any] {
                        do {
                            let jsondata = try JSONSerialization.data(withJSONObject: body , options: .prettyPrinted)
                            let encodedJson = try JSONDecoder().decode(userCustomerModal.self, from: jsondata)
                            self.driverData = encodedJson
                            //                            let dropLat = self.driverData?.drop_lat  ?? ""
                            //                            let dropLong = self.driverData?.drop_long  ?? ""
                            //                            kDestinationLatLong = "\(dropLat)" + "," + "\(dropLong)"
                            //                            kRideStatus = self.driverData?.ride_status  ?? ""
                            self.cancellation_charge = self.driverData?.cancellation_charge  ?? ""
                            //        kConfirmationAction = kRideStatus
                            //                            if kRideStatus == "FAILED"  {
                            //                                self.failedStatusAPI(rideId: self.driverData?.ride_id  ?? "")
                            //                            }
                            //                            if kRideStatus == "COMPLETED"  {
                            //                                self.chooseRideViewHeight_const.constant = 220
                            //                                self.chooseRide_view.isHidden = false
                            //                                self.chooseLbl.text = "Ride Completed!"
                            //                                self.rideNow_btn.isHidden = true
                            //                                //  kRideId = ""
                            //                            }
                            //                            if kRideStatus == "PENDING"{
                            //                                self.chooseRideViewHeight_const.constant = 100
                            //                                self.chooseRide_view.isHidden = false
                            //                                self.rideNow_btn.isHidden = true
                            //                            }
                            self.ride_tableView.reloadData()
                        }catch {
                            print(false, error.localizedDescription)
                        }
                    }
                }else{
                    self.showAlert("Rider RideshareRates", message: msg)
                }
            }
        }
    }
    //MARK:- accept or reject ride api
    func failedStatusAPI(rideId : String ){
        let param = [ "ride_id" : rideId ,"status" : "FAILED"]
        Indicator.shared.showProgressView(self.view)
        self.conn.startConnectionWithPostType(getUrlString: "accept_ride", params: param,authRequired: true) { (value) in
            Indicator.shared.hideProgressView()
            if self.conn.responseCode == 1{
                print(value)
                let msg = (value["message"] as? String ?? "")
                if ((value["status"] as? Int ?? 0) == 1){
                    kNotificationAction = ""
                    self.chooseRide_view.isHidden = true
                    self.mapView.clear()
                    self.dropAddress_lbl.text = "Enter Drop Location"
                    // self.showToast(message: "No riders found in your area")
                    kNotificationAction = ""
                    kConfirmationAction = ""
                    self.ride_tableView.isHidden = true
                    self.showAlert("Rider RideshareRates", message: "No Driver found in your area")
                }else{
                    self.showAlert("Rider RideshareRates", message: msg)
                }
            }
            else{
                guard let stat = value["Error"] as? String, stat == "ok" else {
                    return
                }
            }
        }
    }
    //MARK:- accept or reject ride api
    func acceptRejectStatus(rideId : String ){
        let param = [ "ride_id" : rideId ,"status" : "PENDING"]
        kConfirmationAction = "PENDING"
        Indicator.shared.showProgressView(self.view)
        self.conn.startConnectionWithPostType(getUrlString: "accept_ride", params: param,authRequired: true) { (value) in
            Indicator.shared.hideProgressView()
            if self.conn.responseCode == 1{
                print(value)
                let msg = (value["message"] as? String ?? "")
                if ((value["status"] as? Int ?? 0) == 1){
                    self.timerr = Timer.scheduledTimer(timeInterval: 120.0, target: self, selector: #selector(self.failedTimer(_:)), userInfo: nil, repeats: false)
                    kNotificationAction = "PENDING"
                    kConfirmationAction = "PENDING"
                    self.ride_tableView.reloadData()
                    //   self.getRideStatus(ride_id: kRideId)
                }else{
                    self.showAlert("Rider RideshareRates", message: msg)
                }
            }
            else{
                guard let stat = value["Error"] as? String, stat == "ok" else {
                    return
                }
            }
        }
    }
    //MARK:- accept or reject ride api with CANCELLED status
    func cancelRideStatus(rideId : String){
        let param = [ "ride_id" : rideId ,"status" : "CANCELLED"]
        kConfirmationAction = "CANCELLED"
        Indicator.shared.showProgressView(self.view)
        self.conn.startConnectionWithPostType(getUrlString: "accept_ride", params: param,authRequired: true) { (value) in
            Indicator.shared.hideProgressView()
            if self.conn.responseCode == 1{
                print(value)
                let msg = (value["message"] as? String ?? "")
                if ((value["status"] as? Int ?? 0) == 1){
                    // self.dropAddress_lbl.text = ""
                    self.dropAddress_lbl.text = "Enter Drop Location"
                    self.pickupBtn.isUserInteractionEnabled = true
                    self.dropBtn.isUserInteractionEnabled = true
                    self.pickupBtnCancel.isUserInteractionEnabled = true
                    self.dropBtnCancel.isUserInteractionEnabled = true
                    self.chooseRideViewHeight_const.constant = 0
                    self.mapView.clear()
                    kNotificationAction = ""
                    kConfirmationAction = ""
                    kRideId = ""
                    self.chooseRide_view.isHidden = true
                    
                    if self.pendingRidetimeout == "true"{
                        self.showAlert("Rider RideshareRates", message: "No Driver available near to your Pick up location. Please Try again after sometime.")
                        self.getLastRideDataApi()
                    }else{
                        self.showAlert("Rider RideshareRates", message: "Ride has been successfully cancelled.")
                        self.getLastRideDataApi()
                    }
                  
                    //   self.ride_tableView.reloadData()
                }else{
                    self.showAlert("Rider RideshareRates", message: "No Driver available near to your Pick up location. Please Try again after sometime.")
                }
            }else{
                guard let stat = value["Error"] as? String, stat == "ok" else {
                    return
                }
            }
        }
    }
    //MARK:- api to change ride status
//    func changeRideStatus(rideId : String,status : String){
//        let param = ["ride_id": rideId , "status" : status]
//        print(param)
//        Indicator.shared.showProgressView(self.view)
//        self.conn.startConnectionWithPostType(getUrlString: "change_ride_status", params: param,authRequired: true) { (value) in
//            print(value)
//            Indicator.shared.hideProgressView()
//            if self.conn.responseCode == 1{
//                // print(value)
//                let msg = (value["message"] as? String ?? "")
//                if ((value["status"] as? Int ?? 0) == 1){
//                    if let body = (value as? [String:Any])?["data"] as? [String:Any] {
//                    }
//                }else{
//                    self.showAlert("Rider RideshareRates", message: msg)
//                }
//            }
//            else{
//                guard let stat = value["Error"] as? String, stat == "ok" else {
//                    //       self.showAlert("Rider RideshareRates", message: "\(String(describing: stat))")
//                    return
//                }
//            }
//        }
//    }
    //MARK:- api to get get last ride
    func getLastRideDataApi(){
        Indicator.shared.showProgressView(self.view)
        self.conn.startConnectionWithGetTypeWithParam(getUrlString: "get_last_ride",authRequired: true) { [self] (value) in
            print("Last Ride Data Api  \(value)")
            Indicator.shared.hideProgressView()
            let msg = (value["message"] as? String ?? "")
            if self.conn.responseCode == 1{
                if (value["status"] as? Int ?? 0) == 1{
                    let data = (value["data"] as? [String:Any] ?? [:])
                    
                    do{
                        //                        let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                        //                        let encodedJson = try? JSONDecoder().decode(lastRideModalData.self, from: jsonData)
                        //                        self.lastRideData = encodedJson
                        
                        
                        let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                        self.lastRideData = try newJSONDecoder().decode(lastRideModalData.self, from: jsonData)
                        //                        print(self.lastRideData)
                        
                        let rideStatusData = self.lastRideData?.status ?? ""
                        let is_technical_issue = self.lastRideData?.is_technical_issue ?? ""
                        let paymentStatusData = self.lastRideData?.payment_status ?? ""
                        let feedbackStatus = self.lastRideData?.feedback ?? ""
                        
                        
                        if kNotificationAction == "ACCEPTED" || kConfirmationAction == "ACCEPTED" || kNotificationAction == "NOT_CONFIRMED" || kConfirmationAction == "NOT_CONFIRMED" || kNotificationAction == "PENDING" || kConfirmationAction == "PENDING" || kNotificationAction == "START_RIDE" || kConfirmationAction == "START_RIDE" {
                            dropAddress_lbl.text = self.lastRideData?.drop_address ?? ""
                            pickUpAddress_lbl.text = self.lastRideData?.pickup_adress
                            kCurrentLocaLatLongTap =   "\(self.lastRideData?.pickup_lat ?? "")" + "," + "\(self.lastRideData?.pickup_long ?? "")"
                            
                            kDestinationLatLongTap = "\(self.lastRideData?.drop_lat ?? "")" + "," + "\(self.lastRideData?.drop_long ?? "")"
                        }
                        kRideId = self.lastRideData?.ride_id ?? ""
                        
                        if rideStatusData != ""{
                            if rideStatusData == "CANCELLED"{
                                self.mapView.clear()
                                kNotificationAction = ""
                                kConfirmationAction = ""
                                kRideId = ""
                                self.pickupBtn.isUserInteractionEnabled = true
                                self.dropBtn.isUserInteractionEnabled = true
                                self.pickupBtnCancel.isUserInteractionEnabled = true
                                self.dropBtnCancel.isUserInteractionEnabled = true
                                self.chooseRide_view.isHidden = true
                                self.ride_tableView.isHidden = true
                                self.chooseRideViewHeight_const.constant = 0
                                
                            }
                            if rideStatusData == "DELETED"{
                                kNotificationAction = ""
                                kConfirmationAction = ""
                                self.chooseRide_view.isHidden = true
                                self.ride_tableView.isHidden = true
                                self.chooseRideViewHeight_const.constant = 0
                            }
                            if rideStatusData == "FAILED"{
                                kNotificationAction = ""
                                kConfirmationAction = ""
                                self.chooseRide_view.isHidden = true
                                self.ride_tableView.isHidden = true
                                self.chooseRideViewHeight_const.constant = 0
                            }
                            if rideStatusData == "PENDING"{
                                self.timerr = Timer.scheduledTimer(timeInterval: 120.0, target: self, selector: #selector(self.failedTimer(_:)), userInfo: nil, repeats: false)
                                if pendingRidetimeout == "true"{
                                    self.cancelRideStatus(rideId: kRideId)
                                }
                            }
                            if rideStatusData == "ACCEPTED"{
                                kNotificationAction = "ACCEPTED"
                                kConfirmationAction = "ACCEPTED"
                            }
                            //  if "START_RIDE"
                            if rideStatusData == "START_RIDE"{
                                kNotificationAction = "START_RIDE"
                                kConfirmationAction = "START_RIDE"
                            }
                            if rideStatusData == "COMPLETED"{
                                self.getRideStatus(ride_id: kRideId)
                                kNotificationAction = "COMPLETED"
                                kConfirmationAction = "COMPLETED"
                                
                            }
                            if rideStatusData == "PENDING"{
                                // self.getRideStatus(ride_id: kRideId)
                                kNotificationAction = "PENDING"
                                kConfirmationAction = "PENDING"
                                
                            }
                            
                            //                            else{
                            //                                kNotificationAction = rideStatusData
                            //                                kConfirmationAction = rideStatusData
                            //                            }
                            //                            if rideStatusData == "COMPLETED"  && paymentStatusData != "COMPLETED" {
                            //                                if is_technical_issue == "Yes"{
                            //
                            //                                    let refreshAlert = UIAlertController(title: "Rider RideshareRates", message: "Driver wants to drop off you before \n reaching destination. Do you want to complete this ride?", preferredStyle: UIAlertController.Style.alert)
                            //
                            //                                    refreshAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                            //
                            //                                        let refreshAlert = UIAlertController(title: "Rider RideshareRates", message: "Payment is automatically debit for this ride.", preferredStyle: UIAlertController.Style.alert)
                            //
                            //                                        refreshAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                            //                                           // print("autoPAyment")
                            //                                            self.savedCardApi()
                            //                                        }))
                            //
                            //                                        refreshAlert.addAction(UIAlertAction(title: "No", style: .default, handler: { (action: UIAlertAction!) in
                            //                                            refreshAlert.dismiss(animated: true, completion: nil)
                            //                                        }))
                            //
                            //                                        present(refreshAlert, animated: true, completion: nil)
                            //
                            //                                    }))
                            //                                    // "Driver NOT wants to drop off you before \n reaching destination. Do you want to complete this ride?"
                            //                                    refreshAlert.addAction(UIAlertAction(title: "No", style: .default, handler: { (action: UIAlertAction!) in
                            //                                        let url: NSURL = URL(string: "TEL://802-375-5793")! as NSURL
                            //                                           UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
                            //                                    }))
                            //
                            //                                    present(refreshAlert, animated: true, completion: nil)
                            //
                            //                                    kNotificationAction = ""
                            //                                    kConfirmationAction = ""
                            //                                    self.chooseRide_view.isHidden = true
                            //                                    self.ride_tableView.isHidden = true
                            //                                }
                            ////                                timerr = Timer.scheduledTimer(timeInterval: 240.0, target: self, selector: #selector(cancelAutomatically(_:)), userInfo: nil, repeats: false)
                            //
                            //                            }
                            
                            
                        }
                        if paymentStatusData == "COMPLETED"{
                            kRideId = ""
                            //                            if is_technical_issue == "Yes"{
                            //                                self.showAlert("Rider RideshareRates", message: "Sorry your last ride was completed due to technical issue")
                            //                                kNotificationAction = ""
                            //                                kConfirmationAction = ""
                            //                                self.chooseRide_view.isHidden = true
                            //                                self.ride_tableView.isHidden = true
                            //                            }else{
                            if rideStatusData ==  "COMPLETED" && paymentStatusData ==  "COMPLETED"{
                                if feedbackStatus == "1"{
                                    kNotificationAction = ""
                                    kConfirmationAction = ""
                                }
                                else{
                                    kNotificationAction = "FEEDBACK"
                                    kConfirmationAction = "FEEDBACK"
                                    self.dropAddress_lbl.text  = self.lastRideData?.drop_address ?? ""
                                    
                                }
                            }
                            else{
                                kNotificationAction = ""
                                kConfirmationAction = ""
                                self.chooseRide_view.isHidden = true
                                self.ride_tableView.isHidden = true
                            }
                            //           }
                            
                            
                        }
                        self.ride_tableView.reloadData()
                    }
                    catch{
                        print("Error is here")
                        print(error.localizedDescription)
                    }
                }
                else{
                    
                }
            }
            else{
                print("No Ride Available")
                guard let stat = value["Error"] as? String, stat == "ok" else {
                    //     print(stat)
                   
                    return
                }
            }
        }
    }
    //MARK:- cancel ride popup
    func cancelButtonAlert() {
        if kNotificationAction == "ACCEPTED" || kConfirmationAction == "ACCEPTED" && kRideId != "" {
            var refreshAlert = UIAlertController(title: "Rider RideshareRates" , message: "If you cancel the confirmed ride after 4 min than $\(self.lastRideData?.cancellation_charge ?? "") cancellation charge will be added in your next ride. Do you want to cancel this ride?", preferredStyle: UIAlertController.Style.alert)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                
                NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16),
                NSAttributedString.Key.foregroundColor: UIColor.white,
            ]
            let messageAttributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15),
                .foregroundColor: UIColor.white,
            ]

            let attributedTitle = NSAttributedString(string: "Rider RideshareRates", attributes: titleAttributes)
            let attributedMessage = NSAttributedString(string: "If you cancel the confirmed ride after 4 min than $\(self.lastRideData?.cancellation_charge ?? "") cancellation charge will be added in your next ride. Do you want to cancel this ride?", attributes: messageAttributes)

            // Set the attributed title and message
            refreshAlert.setValue(attributedTitle, forKey: "attributedTitle")
            refreshAlert.setValue(attributedMessage, forKey: "attributedMessage")
            refreshAlert.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = #colorLiteral(red: 0.1490196078, green: 0.1490196078, blue: 0.1490196078, alpha: 0.96)
            
            refreshAlert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (action: UIAlertAction!) in
                if kRideId != ""{
                    self.cancelRideStatus(rideId: kRideId)
                }
            }))
            refreshAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
            }))
            present(refreshAlert, animated: true, completion: nil)
            
        }else{
            var refreshAlert = UIAlertController(title: "Rider RideshareRates" , message: "Do you want to cancel your ride ?", preferredStyle: UIAlertController.Style.alert)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                
                NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16),
                NSAttributedString.Key.foregroundColor: UIColor.white,
            ]
            let messageAttributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15),
                .foregroundColor: UIColor.white,
            ]

            let attributedTitle = NSAttributedString(string: "Rider RideshareRates", attributes: titleAttributes)
            let attributedMessage = NSAttributedString(string: "Do you want to cancel your ride ?", attributes: messageAttributes)

            // Set the attributed title and message
            refreshAlert.setValue(attributedTitle, forKey: "attributedTitle")
            refreshAlert.setValue(attributedMessage, forKey: "attributedMessage")
            refreshAlert.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = #colorLiteral(red: 0.1490196078, green: 0.1490196078, blue: 0.1490196078, alpha: 0.96)
            refreshAlert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (action: UIAlertAction!) in
                if kRideId != ""{
                    self.mTimerView.isHidden = true
                    self.cancelRideStatus(rideId: kRideId)
                }
            }))
            refreshAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
            }))
            present(refreshAlert, animated: true, completion: nil)
            
        }
    }
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject]
                return json
            } catch {
                print("Something went wrong")
            }
        }
        return nil
    }
    func getTime(){
        
        let param : [String : Any] = ["ride_id" : kRideId] as [String : Any]
        Indicator.shared.showProgressView(self.view)
        let urlString = "\(baseURL)rideTime"
        let url = URL.init(string: urlString)
        var headers: HTTPHeaders = [:]
        headers = ["Authorization" : "Bearer " + (UserDefaults.standard.value(forKey: "token") as? String ?? "")
        ]
        print(headers)
        print(param)
        
        AF.request(urlString, method: .post, parameters: param, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                print("responseString: \(response)")
                Indicator.shared.hideProgressView()
                switch (response.result) {
                case .success(let JSON):
                    print("JSON: \(JSON)")
                    
                    let str =  "\(JSON)"
                    
                    let dict = self.convertStringToDictionary(text: str)
                    print("Finally dict is here=======\(dict)")
                    
                    if let detailsDict = dict as NSDictionary? {
                        print("Parse Data")
                        let msg = detailsDict["message"] as? String ?? ""
                        print(msg)
                        if (dict?["status"] as? Int ?? 0) == 1 {
                            
                            if let result = dict!["result"] as? [String: Any] {
                                // Access current_time and ride_created_time
                                if let currentTime = result["current_time"] as? String,
                                   let rideCreatedTime = result["ride_created_time"] as? String {
                                    print("Current Time: \(currentTime)")
                                    print("Ride Created Time: \(rideCreatedTime)")
                                    self.timer(rideCreatedTimeString: rideCreatedTime, currentTimeString: currentTime)
                                }
                            }
                            // self.setdefaultCardApi(card_id: card_id, is_default: "1")
                            // self.showAlertWithBackButton("Rider RideshareRates", message: "\(msg)")
                        }
                        else{
                            self.showAlert("Rider RideshareRates", message: "\(msg)")
                        }
                    }
                    break;
                case .failure(let error):
                    print(error)
                    self.showAlert("Rider RideshareRates", message: "\(error.localizedDescription)")
                    break
                }
            }
        
    }
    func timer(rideCreatedTimeString : String, currentTimeString :String ){
        // Assuming you have the ride_created_time and current_time as strings
//        let rideCreatedTimeString = "2024-01-19 12:01:34"
//        let currentTimeString = "2024-01-19 12:14:33"

        // Create date formatters
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

      

        // Parse the date strings
        if let rideCreatedTime = dateFormatter.date(from: rideCreatedTimeString),
           let currentTime = dateFormatter.date(from: currentTimeString) {
            
            // Calculate the time difference
            let timeDifference = currentTime.timeIntervalSince(rideCreatedTime)
            
            // Convert the time difference to seconds
            let secondsDifference = Int(timeDifference)
            self.count = secondsDifference
            timeupdate()
        } else {
            print("Error parsing dates")
        }
        
    }
    func timeupdate(){
     //   count = NSUSERDEFAULT.value(forKey: Ktimer) as? Int ?? 0
      //  NavigationManager.pushToLoginVC(from: self)
        stopTimer()
        DispatchQueue.main.async {
            self.timerS =  Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTimervalue), userInfo: nil, repeats: true)
            print("1.0")
        }
    }
    // Stop the timer when needed
    func stopTimer() {
        if timerS != nil{
            self.timerS!.invalidate()
            self.timerS = nil
        }
        
    }
    @objc func updateTimervalue() {
        if self.stoptimer == "stop"{
            stopTimer()
        }else{
            let time = timeString(time: TimeInterval(self.count))
            DispatchQueue.main.async {
              
                self.mTimerLBL.text = time
                print(time)
            }
        }
      //  stopTimer()
    }
    func timeString(time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        self.count = self.count + 1
        print(count)
        if count > 240{
            mTimerView.isHidden = true
        }else{
            if kNotificationAction == "ACCEPTED" || kConfirmationAction == "ACCEPTED"{
                self.mTimerView.isHidden = false
            }else{
                mTimerView.isHidden = true
            }
        }
        return String(format:"%02i:%02i", minutes, seconds)
    }
}
extension HomeViewController : tipPopup{
    func tip(amount: String?) {
        print("Last Ride data")
        let modalData = lastRideData
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PaymentVC") as! PaymentVC
        vc.screen = "tip"
        vc.completedStatus = true
        vc.completedRideId = modalData?.ride_id ?? ""
        vc.completedAmount =  amount ?? ""
        vc.vcCome = comeFrom.CompletedRequest
        vc.lastRideData =  lastRideData
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
//autopayment
extension HomeViewController{
    
    //MARK:- save card api
    
    func savedCardApi(){
        Indicator.shared.showProgressView(self.view)
        self.conn.startConnectionWithGetTypeWithParam(getUrlString: "card_list",authRequired: true) { (value) in
            Indicator.shared.hideProgressView()
            if self.conn.responseCode == 1{
                print(value)
                if (value["status"] as? Int ?? 0) == 1{
                    let data = (value["data"] as? [[String:AnyObject]] ?? [[:]])
                    do{
                        let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                        self.cardData = try newJSONDecoder().decode(userCardData.self, from: jsonData)
                        self.autoPay()
                    }catch{
                        print(error.localizedDescription)
                    }
                }
            }
            else{
                self.showAlert("Rider RideshareRates", message: "Could not get response")
            }
        }
    }
    //MARK:- auto payemnt on cancel ride
    func autoPay(){
        for i in 0..<cardData.count{
            if cardData[i].is_default == "1"{
                cardID = cardData[i].id!
                //                let modalData = lastRideData
                //                payApi(rideId: modalData?.ride_id ?? "", amount: modalData?.total_amount ?? "" , card_id: cardData[i].id!)
            }
        }
    }
    //MARK:- payment api
    func payApi(rideId:String,amount:String,card_id:String){
        let param = ["ride_id":rideId,"amount":amount ,"card_id" : card_id]
        print(param)
        Indicator.shared.showProgressView(self.view)
        let urlString = "\(baseURL)payment"
        let url = URL.init(string: urlString)
        var headers: HTTPHeaders = [:]
        headers = ["Authorization" : "Bearer " + (UserDefaults.standard.value(forKey: "token") as? String ?? "")
        ]
        print(headers)
        AF.request(urlString, method: .post, parameters: param, encoding: URLEncoding.default, headers: headers)
            .responseString { response in
                print("responseString: \(response)")
                Indicator.shared.hideProgressView()
                switch (response.result) {
                case .success(let JSON):
                    print("JSON: \(JSON)")
                    
                    let str =  "\(JSON)"
                    
                    let dict = self.convertStringToDictionary(text: str)
                    print("Finally dict is here=======\(dict)")
                    
                    if let detailsDict = dict as NSDictionary? {
                        print("Parse Data")
                        let msg = detailsDict["message"] as? String ?? ""
                        print(msg)
                        if (dict?["status"] as? Int ?? 0) == 1 {
                            // self.setdefaultCardApi(card_id: card_id, is_default: "1")
                            self.showAlertWithBackButton("Rider RideshareRates", message: "\(msg)")
                        }
                        else{
                            self.showAlert("Rider RideshareRates", message: "\(msg)")
                        }
                    }
                    break;
                case .failure(let error):
                    print(error)
                    self.showAlert("Rider RideshareRates", message: "\(error.localizedDescription)")
                    break
                }
            }
    }
}
extension HomeViewController : RideStart{
    func RideStart(button: String?) {
        if button == "ridenow"{
            if Double(holdAmount)! < Double(rideAmount)!{
                self.showAlert("Rider RideshareRates", message: "Your Pre-authorized amount is less than your ride Amount. Please contact to admin at info@ridesharerates.com")
                
            }else{
                let refreshAlert = UIAlertController(title: "Rideshare authorization" , message: "Rideshare authorized to hold $\(holdAmount) for booking your ride.", preferredStyle: UIAlertController.Style.alert)
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    
                    NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 16),
                    NSAttributedString.Key.foregroundColor: UIColor.white,
                ]
                let messageAttributes: [NSAttributedString.Key: Any] = [
                    NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15),
                    .foregroundColor: UIColor.white,
                ]
                
                let attributedTitle = NSAttributedString(string: "Rideshare authorization", attributes: titleAttributes)
                let attributedMessage = NSAttributedString(string: "Rideshare authorized to hold $\(holdAmount) for booking your ride.", attributes: messageAttributes)
                
                // Set the attributed title and message
                refreshAlert.setValue(attributedTitle, forKey: "attributedTitle")
                refreshAlert.setValue(attributedMessage, forKey: "attributedMessage")
                refreshAlert.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = #colorLiteral(red: 0.1490196078, green: 0.1490196078, blue: 0.1490196078, alpha: 0.96)
                
                refreshAlert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (action: UIAlertAction!) in
                    
                    self.holdpayment()
                    //  self.updateStatus(updateStatus: "3")
                    
                }))
                refreshAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
                }))
                present(refreshAlert, animated: true, completion: nil)
                
            }
        }else{
                self.getLastRideDataApi()
                self.mapView.clear()
                self.dropAddress_lbl.text = "Enter Drop Location"
                
            }
        
    }
    
    func holdpayment(){
        let param = ["amount": holdAmount, "card_id": cardID]
        Indicator.shared.showProgressView(self.view)
        self.conn.startConnectionWithPostType(getUrlString: "add_payment", params: param,authRequired: true) { (value) in
            //   print(value)
            let msg = (value["message"] as? String ?? "")
            Indicator.shared.hideProgressView()
            if self.conn.responseCode == 1{
                print(value)
                if (value["status"] as? Int ?? 0) == 1{
                    txnID = value["txn_id"] as? String ?? ""
                    holdAmount = ""
                    self.rideNowApi()
                }
                else{
                    self.showAlert("Rider RideshareRates", message: msg)
                }
            }
            
        }
    }
        
    
    
    
}

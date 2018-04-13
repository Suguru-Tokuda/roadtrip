import UIKit
import GoogleMaps
import GooglePlaces

class MapViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
    var gasPricesDataStore: GasPricesDataStore?
    var locationManager = CLLocationManager()
    var destination: CLLocationCoordinate2D?
    
    @IBOutlet weak var mapView: GMSMapView!
    
    lazy var googleClient = GoogleClient()
    var myCar: Car?
    var currentLocation: CLLocation?
    var lastLocation: CLLocation?
    var searchKeywords:[String] = []
    var locationPetrol : String = "petrol"
    var locationGasStation : String = "gas_station"
    var locationPizza : String = "pizza"
    var locationBurger : String = "burger"
    var searchRadius : Int = 1000
    let searchBar = UISearchBar()
    var isInNavigation: Bool = false
    var markers=[String:[PlaceMarker]]()
    var stackView: UIStackView?
    var currentTime: Date?
    var lastTime: Date?
    var lastTimeToCheckSpeed: Date?
    var reacheableLegs = [Direction.Route.Leg]()
    var zoom: Float?
    var usingCompus: Bool = false
    var directionBtn: UIButton!
    
    var gasStationsDuringNavigation = GasStations()
    var navigationDirection: Direction?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myCar = appDelegate!.myCar
        gasPricesDataStore = appDelegate!.gasPricesDataStore
        zoom = 6
        
        directionBtn = UIButton(type: .system) as UIButton
        directionBtn.addTarget(self, action: #selector(locationBtnTapped), for: .touchUpInside)
        directionBtn.setImage(UIImage(named: "locationIcon"), for: .normal)
        directionBtn.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        directionBtn.translatesAutoresizingMaskIntoConstraints = false
        
        self.mapView.addSubview(directionBtn!)
        
        directionBtn!.widthAnchor.constraint(equalToConstant: 100).isActive = true
        directionBtn!.heightAnchor.constraint(equalToConstant: 100).isActive = true
        directionBtn!.trailingAnchor.constraint(equalTo: self.mapView.trailingAnchor, constant: 10).isActive = true;
        directionBtn!.bottomAnchor.constraint(equalTo: self.mapView.bottomAnchor, constant: -50).isActive = true;
        
        //adding all to search        
        locationManager.delegate = self
        locationManager.startUpdatingHeading()
        mapView.delegate = self
        //self.navigationController?.isNavigationBarHidden = true
        locationManager.requestWhenInUseAuthorization()
        
        // expandableview to end of code
        addingSearchAndFilterButtonToRightNavigation()
        // setting spanner for getting to settings
        let settingsBtn: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "spanner")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(settingsTapped(_:)))
        self.navigationItem.leftBarButtonItem = settingsBtn
        
        // setting the navigation bar to transparent
        self.navigationController?.presentTransparentNavigationBar()
        isInNavigation = false
    }
    
}

// MARK: location manager functions
extension MapViewController {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else {
            return
        }
        locationManager.startUpdatingLocation()
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            lastLocation = location
            lastTime = Date()
            lastTimeToCheckSpeed = Date()
        }
        guard let location = locations.first else {
            return
        }
        
        /*
         Every 5 seconds, check the current speed and put the speed into the speeds, array of Double
         */
        if lastTimeToCheckSpeed!.timeIntervalSinceNow >= 5.0 {
            self.myCar!.appendSpeed(speed: self.locationManager.location!.speed)
            lastTimeToCheckSpeed = Date() // assiging the current time
        }
        
        /*
         If 5 minutes have passed, it gets the distance between the current and last locations.
         Then it will reduce the fuel remaining.
         */
        if lastTime!.timeIntervalSinceNow >= 5.0 * 60 {
            googleClient.getDistance(origin: lastLocation!, destination: location) { (distanceResult) in
                switch distanceResult {
                case let .success(distance):
                    let distanceParam = distance.rows![0].elements![0].distance!.value
                    self.lastLocation = self.currentLocation
                    self.currentLocation = location
                    self.myCar!.consumeFuel(speed: self.myCar!.getAverageSpeed(), distance: distanceParam!)
                    self.myCar!.resetSpeeds()
                case let .failure(error):
                    print(error)
                }
            }
        }
        if !usingCompus {
            mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: zoom!, bearing: 0, viewingAngle: 0)
        }
        clearAllMarkers()
        for keyword in searchKeywords{
            self.fetchGoogleData(forLocation: location, locationName: keyword, searchRadius: self.searchRadius )
        }
        currentLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if usingCompus {
            self.mapView.camera = GMSCameraPosition.camera(withLatitude: currentLocation!.coordinate.latitude, longitude: currentLocation!.coordinate.longitude, zoom: zoom!, bearing: newHeading.magneticHeading, viewingAngle: 0)
            
        }
    }
}

// MARK: GoogleAPI calls from Controller
extension MapViewController {
    
    func fetchAllFor(getMarkerType markerType:String)->[PlaceMarker] {
        for (key, values) in markers{
            if key == markerType{
                return values
            }
        }
        return []
    }
    
    func clearAllMarkers(){
        for ( _, values) in markers {
            for value in values{
                value.map = nil
            }
        }
        markers.removeAll()
    }
    
    func clearMarkers(forType typeToClear:String){
        for marker in markers[typeToClear]!{
            marker.map = nil
        }
        markers.removeValue(forKey: typeToClear)
    }
    
    func addMarker(markerType:String,marker:PlaceMarker){
        if markers[markerType] == nil {
            markers[markerType]=[]
        }
        markers[markerType]?.append(marker)
    }
    
    func setMarkersWhileNavigation(){
        if isInNavigation {
            let group5 = DispatchGroup()
            group5.enter()
                for leg in self.reacheableLegs{
                    for step in leg.steps!{
                        
                        
                        self.gasPricesDataStore?.getGasPrices(latitude: step.startLocation!.lat!, longitutde: step.startLocation!.lng!, distanceInMiles: 1, gasType: "reg"){
                            (response) in
                            DispatchQueue.main.async{
                            switch response{
                            case let .success(gasStations):
                                if self.gasStationsDuringNavigation.stations == nil{
                                 self.gasStationsDuringNavigation = gasStations
                                }else{
                                    self.gasStationsDuringNavigation.stations! += gasStations.stations!
                                }
                                
                                if self.reacheableLegs.last!.steps!.last?.startLocation?.lat == step.startLocation?.lat && self.reacheableLegs.last!.steps!.last?.startLocation?.lng == step.startLocation?.lng {
                                    group5.leave()
                                }
                                
                            case let .failure(error):
                                print(error)
                            }
                        }
                        
                    }
                }
                
            }
            
            group5.notify(queue: .main, execute: {
                if let _ = self.gasStationsDuringNavigation.stations{
                    for station in self.gasStationsDuringNavigation.stations!.sorted(by: {$0.lat!<$1.lat!}){
                        print("lat:\(station.lat!) lng:\(station.lng!)")
                        
                    }
                    self.gasStationsDuringNavigation.stations = Array(Set(self.gasStationsDuringNavigation.stations!))
                    for station in self.gasStationsDuringNavigation.stations!.sorted(by: {$0.lat!<$1.lat!}){
                        print("lat:\(station.lat!) lng:\(station.lng!)")
                        
                    }
                for gasStationForPrice in self.gasStationsDuringNavigation.stations! {
                    let DynamicView=UIView(frame: CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 50, height: 50)))
                    DynamicView.backgroundColor=UIColor.clear
                    var imageViewForPinMarker : UIImageView
                    imageViewForPinMarker  = UIImageView(frame:CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 50, height: 50)))
                    imageViewForPinMarker.image = UIImage(named:"prices")?.withRenderingMode(.alwaysTemplate)
                    imageViewForPinMarker.tintColor = UIColor.green
                    let text = UILabel(frame:CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 40, height: 30)))
                    guard let _ = gasStationForPrice.regPrice else {
                        continue
                    }
                    text.text = String(gasStationForPrice.regPrice!)
                    text.textColor = UIColor.black
                    text.font = UIFont(name: text.font.fontName, size: 14)
                    text.textAlignment = NSTextAlignment.center
                    text.center = imageViewForPinMarker.convert(imageViewForPinMarker.center, from:imageViewForPinMarker.superview)
                    
                    imageViewForPinMarker.addSubview(text)
                    imageViewForPinMarker.center = DynamicView.convert(DynamicView.center, from:DynamicView.superview)
                    DynamicView.addSubview(imageViewForPinMarker)
                    UIGraphicsBeginImageContextWithOptions(DynamicView.frame.size, false, UIScreen.main.scale)
                    DynamicView.layer.render(in: UIGraphicsGetCurrentContext()!)
                    let imageConverted: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
                    UIGraphicsEndImageContext()
                    let marker = GMSMarker()
                    marker.position = CLLocationCoordinate2DMake(gasStationForPrice.lat!, gasStationForPrice.lng!)
                    
                    marker.groundAnchor = CGPoint(x: 0.5, y: 1)
                    marker.appearAnimation = .pop
                    
                    marker.icon = imageConverted
                    marker.title = gasStationForPrice.station//////incomplete
                    //                                marker.snippet = "The place is \(place.openingHours?.isOpen == true ? "open" : "closed")"
                    marker.map = self.mapView
                    
                }
                }
            })
        }
    }
    
    func fetchGoogleData(forLocation: CLLocation, locationName: String, searchRadius: Int) {
        let group1 = DispatchGroup()
        group1.enter()
        googleClient.getGooglePlacesData(forKeyword: locationName, location: forLocation, withinMeters: searchRadius) { (response) in
            DispatchQueue.main.sync{
                let places = response.results
                for place in places {
                    
                    let marker = PlaceMarker(place: place)
                    marker.title = place.name
                    marker.snippet = "The place is \(place.openingHours?.isOpen == true ? "open" : "closed")"
                    //                    switch true{
                    //                    case place.types.contains("gas_station"),place.types.contains("petrol"):
                    if locationName == "gas_station" || locationName == "petrol"{
                        let DynamicView=UIView(frame: CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 50, height: 50)))
                        DynamicView.backgroundColor=UIColor.clear
                        var imageViewForPinMarker : UIImageView
                        imageViewForPinMarker  = UIImageView(frame:CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 50, height: 50)))
                        imageViewForPinMarker.image = UIImage(named:"prices")?.withRenderingMode(.alwaysTemplate)
                        imageViewForPinMarker.tintColor = UIColor.green
                        let text = UILabel(frame:CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 40, height: 30)))
                        text.text = "$2.5"
                        text.textColor = UIColor.black
                        text.font = UIFont(name: text.font.fontName, size: 14)
                        text.textAlignment = NSTextAlignment.center
                        text.center = imageViewForPinMarker.convert(imageViewForPinMarker.center, from:imageViewForPinMarker.superview)
                        
                        imageViewForPinMarker.addSubview(text)
                        imageViewForPinMarker.center = DynamicView.convert(DynamicView.center, from:DynamicView.superview)
                        DynamicView.addSubview(imageViewForPinMarker)
                        UIGraphicsBeginImageContextWithOptions(DynamicView.frame.size, false, UIScreen.main.scale)
                        DynamicView.layer.render(in: UIGraphicsGetCurrentContext()!)
                        let imageConverted: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
                        UIGraphicsEndImageContext()
                        
                        marker.icon = imageConverted
                        marker.map = self.mapView
                    }
                    //                    case place.types.contains("pizza"), place.name.range(of: "pizza", options: .caseInsensitive) != nil:
                    if locationName == "pizza"{
                        marker.icon = UIImage(named: "pizza")
                        marker.map = self.mapView
                    }
                    if locationName == "burger"{
                        marker.icon = UIImage(named: "burger")
                        marker.map = self.mapView
                    }
                    //                    case place.types.contains("food"),place.types.contains("restaurant"),place.types.contains("bar"):
                    //                    if locationName == "food"{
                    //                        marker.icon = UIImage(named: "Food")
                    //                        marker.map = self.mapView
                    //                    }
                    self.addMarker(markerType: locationName, marker: marker)
                }
                group1.leave()
            }
            
        }
        let group2 = DispatchGroup()
        group1.notify(queue: .main, execute: {
            group2.enter()
            self.googleClient.getGooglePlacesData(forKeyword: locationName, location: forLocation, withinMeters: searchRadius) { (response) in
                DispatchQueue.main.sync{
                    let places = response.results
                    for place in places {
                        
                        let marker = PlaceMarker(place: place)
                        marker.title = place.name
                        marker.snippet = "The place is \(place.openingHours?.isOpen == true ? "open" : "closed")"
                        //                        switch true{
                        //                        case place.types.contains("gas_station"):
                        //
                        if locationName == "gas_station" || locationName == "petrol"{
                            
                            let DynamicView=UIView(frame: CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 50, height: 50)))
                            DynamicView.backgroundColor=UIColor.clear
                            var imageViewForPinMarker : UIImageView
                            imageViewForPinMarker  = UIImageView(frame:CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 50, height: 50)))
                            imageViewForPinMarker.image = UIImage(named:"prices")?.withRenderingMode(.alwaysTemplate)
                            imageViewForPinMarker.tintColor = UIColor.green
                            
                            let text = UILabel(frame:CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 40, height: 30)))
                            text.text = "$2.5"
                            text.textColor = UIColor.black
                            text.font = UIFont(name: text.font.fontName, size: 14)
                            text.textAlignment = NSTextAlignment.center
                            text.center = imageViewForPinMarker.convert(imageViewForPinMarker.center, from:imageViewForPinMarker.superview)
                            imageViewForPinMarker.addSubview(text)
                            imageViewForPinMarker.center = DynamicView.convert(DynamicView.center, from:DynamicView.superview)
                            DynamicView.addSubview(imageViewForPinMarker)
                            UIGraphicsBeginImageContextWithOptions(DynamicView.frame.size, false, UIScreen.main.scale)
                            DynamicView.layer.render(in: UIGraphicsGetCurrentContext()!)
                            let imageConverted: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
                            UIGraphicsEndImageContext()
                            
                            marker.icon = imageConverted
                            marker.map = self.mapView
                        }
                        //                        case place.types.contains("pizza"), place.name.range(of: "pizza", options: .caseInsensitive) != nil:
                        if locationName == "pizza"{
                            marker.icon = UIImage(named: "pizza")
                            marker.map = self.mapView
                        }
                        if locationName == "burger"{
                            marker.icon = UIImage(named: "burger")
                            marker.map = self.mapView
                        }
                        //                        case place.types.contains("food"),place.types.contains("restaurant"),place.types.contains("bar"):
                        //                        if locationName == "food"{
                        //                            marker.icon = UIImage(named: "Food")
                        //                            marker.map = self.mapView
                        //                        }
                        self.addMarker(markerType: locationName, marker: marker)
                    }
                    group2.leave()
                }
                
            }
        })
        
        group2.notify(queue: .main, execute: {
            self.googleClient.getGooglePlacesData(forKeyword: locationName, location: forLocation, withinMeters: searchRadius) { (response) in
                DispatchQueue.main.sync{
                    let places = response.results
                    for place in places {
                        
                        let marker = PlaceMarker(place: place)
                        marker.title = place.name
                        marker.snippet = "The place is \(place.openingHours?.isOpen == true ? "open" : "closed")"
                        //                        switch true{
                        //                        case place.types.contains("gas_station"):
                        if locationName == "gas_station"{
                            let DynamicView=UIView(frame: CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 50, height: 50)))
                            DynamicView.backgroundColor=UIColor.clear
                            var imageViewForPinMarker : UIImageView
                            imageViewForPinMarker  = UIImageView(frame:CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 50, height: 50)))
                            imageViewForPinMarker.image = UIImage(named:"prices")?.withRenderingMode(.alwaysTemplate)
                            imageViewForPinMarker.tintColor = UIColor.green
                            let text = UILabel(frame:CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 40, height: 30)))
                            text.text = "$2.5"
                            text.textColor = UIColor.black
                            text.font = UIFont(name: text.font.fontName, size: 14)
                            text.textAlignment = NSTextAlignment.center
                            text.center = imageViewForPinMarker.convert(imageViewForPinMarker.center, from:imageViewForPinMarker.superview)
                            
                            imageViewForPinMarker.addSubview(text)
                            imageViewForPinMarker.center = DynamicView.convert(DynamicView.center, from:DynamicView.superview)
                            
                            DynamicView.addSubview(imageViewForPinMarker)
                            UIGraphicsBeginImageContextWithOptions(DynamicView.frame.size, false, UIScreen.main.scale)
                            DynamicView.layer.render(in: UIGraphicsGetCurrentContext()!)
                            let imageConverted: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
                            UIGraphicsEndImageContext()
                            
                            marker.icon = imageConverted
                            marker.map = self.mapView
                        }
                        //                        case place.types.contains("pizza"), place.name.range(of: "pizza", options: .caseInsensitive) != nil:
                        if locationName == "pizza"{
                            marker.icon = UIImage(named: "pizza")
                            marker.map = self.mapView
                        }
                        if locationName == "burger"{
                            marker.icon = UIImage(named: "burger")
                            marker.map = self.mapView
                        }
                        //                        case place.types.contains("food"),place.types.contains("restaurant"),place.types.contains("bar"):
                        //                        if locationName == "food"{
                        //                            marker.icon = UIImage(named: "Food")
                        //                            marker.map = self.mapView
                        //                        }
                        self.addMarker(markerType: locationName, marker: marker)
                    }
                }
                
            }
        })
        
    }
    
    func drawPath(origin: CLLocation, destination: CLLocation) {
        googleClient.getDirection(origin: origin, destination: destination) { (directionsResult) in
            switch directionsResult {
            case let .success(direction):
                self.navigationDirection = direction
                let overViewPolyine = direction.routes![0].overviewPolyline
                let route = overViewPolyine!.points
                let path: GMSPath = GMSPath(fromEncodedPath: route!)!
                let polyline = GMSPolyline(path: path)
                polyline.strokeWidth = 4
                polyline.strokeColor = .blue
                polyline.geodesic = true
                polyline.map = self.mapView
                // check if start points of each leg is reacheable
                let group5 = DispatchGroup()
                if let legs = direction.routes![0].legs {
                    for leg in legs {
                        let destLat = leg.startLocation!.lat
                        let destLng = leg.startLocation!.lng
                        let destination = CLLocation(latitude: destLat!, longitude: destLng!)
                        
                        group5.enter()
                        self.googleClient.getDistance(origin: self.currentLocation!, destination: destination, completion: { (distanceResult) in
                            DispatchQueue.main.async{
                                switch distanceResult {
                                case let .success(distance):
                                    if let distanceVal = distance.rows![0].elements![0].distance!.value {
                                        let reachableDistanceInMiles = self.myCar!.getFuelRemaining() * self.myCar!.mpgHwy
                                        // if the start location of a leg is reacheable, put into the reacheableLegs array
                                        if distanceVal < reachableDistanceInMiles {
                                            self.reacheableLegs.append(leg)
                                            group5.leave()
                                        }
                                    }
                                case let .failure(error):
                                    print(error)
                                }
                            }
                        })
                    }
                }
                // show gas stations & restaurants on the steps
                group5.notify(queue: .main, execute :{
                    self.isInNavigation = true
                    self.setMarkersWhileNavigation()
                })
                
            case let .failure(error):
                print(error)
            }
        }
    }
    
    func drawPath(origin: CLLocation, destination: CLLocation, waypoint: CLLocation) {
        googleClient.getDirection(origin: origin, destination: destination, waypoint: waypoint, completion: { (directionsResult) in
            switch directionsResult {
            case let .success(direction):
                self.navigationDirection = direction
                let overViewPolyine = direction.routes![0].overviewPolyline
                let route = overViewPolyine!.points
                let path: GMSPath = GMSPath(fromEncodedPath: route!)!
                let polyline = GMSPolyline(path: path)
                polyline.strokeWidth = 4
                polyline.strokeColor = .blue
                polyline.geodesic = true
                polyline.map = self.mapView
            case let .failure(error):
                print(error)
            }
        })
    }
    
}

// MARK: Filter functions
extension MapViewController: FilterTableViewControllerDelegate {
    //    extension forgetting passing the selected filter form FilterViewController
    func typesController(_ controller: FilterTableViewController, didSelectTypes types: [String]) {
        searchKeywords = controller.selectedTypes.sorted()
        for (key, _) in markers{
            if !searchKeywords.contains(key){
                clearMarkers(forType: key)
            }
        }
        for key in searchKeywords{
            if !markers.keys.contains(key){
                self.fetchGoogleData(forLocation: currentLocation!, locationName: key, searchRadius: self.searchRadius )
            }
        }
        dismiss(animated: true)
    }
    
    @objc func filterClicked() {
        self.performSegue(withIdentifier: "GoToFilterController", sender:self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let navigationController = segue.destination as? UINavigationController,
            let controller = navigationController.topViewController as? FilterTableViewController else {
                return
        }
        controller.selectedTypes = searchKeywords
        controller.delegate = self
    }
    
}

// MARK: GMS Auto Complete Functions
extension MapViewController: GMSAutocompleteViewControllerDelegate {
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        let camera = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude, longitude: place.coordinate.longitude, zoom: 15.0)
        self.mapView.camera = camera
        view = self.mapView
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        marker.title = place.name
        marker.snippet = place.formattedAddress
        marker.map = self.mapView
        
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        mapView.settings.zoomGestures = true
        mapView.settings.tiltGestures = true
        
        print("Place name: \(place.name)")
        print("Place address: \(String(describing: place.formattedAddress))")
        print("Place attributions: \(String(describing: place.attributions))")
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print("Error: ", error.localizedDescription)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        self.isInNavigation = false
        dismiss(animated: true, completion: nil)
    }
    
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}

//MARK: GMS delegate functions
extension MapViewController {
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        // setting the position to destination's coordinate
        self.destination = marker.position
        
        let getDirectionBtn = UIButton(type: .system)
        getDirectionBtn.frame = CGRect(x: 150, y: 100, width: 150, height: 30)
        getDirectionBtn.setTitle("Get Direction", for: .normal)
        getDirectionBtn.backgroundColor = UIColor(red:0.00, green:0.53, blue:1.00, alpha:1.0)
        getDirectionBtn.layer.cornerRadius = 5
        getDirectionBtn.setTitleColor(.white, for: .normal)
        getDirectionBtn.addTarget(self, action: #selector(getDirectionBtnTapped), for: .touchUpInside)
        
        let cancelBtn = UIButton(type: .system)
        cancelBtn.frame = CGRect(x: 150, y: 100, width: 150, height: 30)
        cancelBtn.setTitle("Cancel", for: .normal)
        cancelBtn.backgroundColor = UIColor(red:1.00, green:0.30, blue:0.00, alpha:1.0)
        cancelBtn.layer.cornerRadius = 5
        cancelBtn.setTitleColor(.white, for: .normal)
        cancelBtn.addTarget(self, action: #selector(cancelBtnTapped), for: .touchUpInside)
        
        getDirectionBtn.translatesAutoresizingMaskIntoConstraints = false
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        
        getDirectionBtn.widthAnchor.constraint(equalToConstant: 140).isActive = true
        getDirectionBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        cancelBtn.widthAnchor.constraint(equalToConstant: 140).isActive = true
        cancelBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        // adding buttons to the subview
        self.stackView = UIStackView(arrangedSubviews: [getDirectionBtn, cancelBtn])
        self.stackView!.axis = .vertical
        self.stackView!.spacing = 30
        // enables auto layout for buttons
        self.stackView!.translatesAutoresizingMaskIntoConstraints = false
        self.mapView.addSubview(stackView!)
        
        self.stackView!.centerXAnchor.constraint(equalTo: self.mapView.centerXAnchor).isActive = true
        self.stackView!.bottomAnchor.constraint(lessThanOrEqualTo: self.mapView.bottomAnchor, constant: -50).isActive = true
        return false
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        print("infowindow tapped")
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        //hiding keyboard on taping map
        searchBar.resignFirstResponder()
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        self.zoom = position.zoom
    }
    
}

// MARK: needs to be changed - Sanket
extension MapViewController {
    
    func addingSearchAndFilterButtonToRightNavigation(){
        let imgforsearch = UIImage(named: "search")!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        let imgforfilter = UIImage(named: "filter")!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        let searchButton = UIBarButtonItem(image: imgforsearch, style: .plain, target: self, action: #selector(toggle))
        let forfilter = UIBarButtonItem(image: imgforfilter, style: .plain, target: self, action: #selector(filterClicked))
        navigationItem.setRightBarButtonItems([searchButton,forfilter], animated: true)
    }
}

// MARK: Custom functions
extension MapViewController {
    @objc func settingsTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showCarSummary", sender: self)
    }
    
    @objc func getDirectionBtnTapped(_ sender: UIButton) {
        let currentLocation = self.currentLocation
        let destination = CLLocation(latitude: self.destination!.latitude, longitude: self.destination!.longitude)
        
        let currentLocation2D = CLLocationCoordinate2D(latitude: currentLocation!.coordinate.latitude, longitude: currentLocation!.coordinate.longitude)
        let destination2D = CLLocationCoordinate2D(latitude: destination.coordinate.latitude, longitude: destination.coordinate.longitude)
        
        let bounds = GMSCoordinateBounds(coordinate: currentLocation2D, coordinate: destination2D)
        var insets = UIEdgeInsets()
        insets.bottom = 50
        insets.top = 50
        insets.right = 50
        insets.left = 50
        let camera = self.mapView.camera(for: bounds, insets: insets)!
        self.mapView.camera = camera
        
        self.drawPath(origin: currentLocation!, destination: destination)
        
        // remove buttons from the view
        self.stackView!.removeFromSuperview()
        
        let startNavBtn = UIButton(type: .system)
        startNavBtn.frame = CGRect(x: 150, y: 100, width: 150, height: 30)
        startNavBtn.setTitle("Start Navigation", for: .normal)
        startNavBtn.backgroundColor = UIColor(red:0.00, green:0.53, blue:1.00, alpha:1.0)
        startNavBtn.layer.cornerRadius = 5
        startNavBtn.setTitleColor(.white, for: .normal)
        startNavBtn.addTarget(self, action: #selector(startNavBtnTapped), for: .touchUpInside)
        
        let cancelBtn = UIButton(type: .system)
        cancelBtn.frame = CGRect(x: 150, y: 100, width: 150, height: 30)
        cancelBtn.setTitle("Cancel", for: .normal)
        cancelBtn.backgroundColor = UIColor(red:1.00, green:0.30, blue:0.00, alpha:1.0)
        cancelBtn.layer.cornerRadius = 5
        cancelBtn.setTitleColor(.white, for: .normal)
        cancelBtn.addTarget(self, action: #selector(cancelBtnTapped), for: .touchUpInside)
        
        startNavBtn.translatesAutoresizingMaskIntoConstraints = false
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        
        startNavBtn.widthAnchor.constraint(equalToConstant: 140).isActive = true
        startNavBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        cancelBtn.widthAnchor.constraint(equalToConstant: 140).isActive = true
        cancelBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        // adding buttons to the subview
        self.stackView = UIStackView(arrangedSubviews: [startNavBtn, cancelBtn])
        self.stackView!.axis = .vertical
        self.stackView!.spacing = 30
        // enables auto layout for buttons
        self.stackView!.translatesAutoresizingMaskIntoConstraints = false
        self.mapView.addSubview(stackView!)
        
        self.stackView!.centerXAnchor.constraint(equalTo: self.mapView.centerXAnchor).isActive = true
        self.stackView!.bottomAnchor.constraint(lessThanOrEqualTo: self.mapView.bottomAnchor, constant: -50).isActive = true
    }
    
    @objc func startNavBtnTapped(_ sender: UIButton) {
        print("startNavBtnTapped")
    }
    
    @objc func cancelBtnTapped(_ sender: UIButton) {
        print("cancelbtn tapped")
        self.mapView.clear()
        let camera = GMSCameraPosition.camera(withLatitude: self.currentLocation!.coordinate.latitude, longitude: self.currentLocation!.coordinate.longitude, zoom: 16)
        self.mapView.camera = camera
        self.stackView?.removeFromSuperview()
    }
    
    @objc func locationBtnTapped(_ sender: UIButton) {
        self.usingCompus = !self.usingCompus
    }
    
    //    part of expandable search bar
    @objc func toggle() {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
}

//part of expandable search bar
class ExpandableView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override var intrinsicContentSize: CGSize {
        return UILayoutFittingExpandedSize
    }
}

extension UINavigationController {
    
    public func presentTransparentNavigationBar() {
        navigationBar.setBackgroundImage(UIImage(), for:.default)
        navigationBar.isTranslucent = true
        navigationBar.shadowImage = UIImage()
        setNavigationBarHidden(false, animated:true)
    }
    
    public func hideTransparentNavigationBar() {
        setNavigationBarHidden(true, animated:false)
        navigationBar.setBackgroundImage(UINavigationBar.appearance().backgroundImage(for: UIBarMetrics.default), for:.default)
        navigationBar.isTranslucent = UINavigationBar.appearance().isTranslucent
        navigationBar.shadowImage = UINavigationBar.appearance().shadowImage
    }
}



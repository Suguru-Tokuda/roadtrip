import UIKit
import GoogleMaps
import GooglePlaces
import CoreLocation

class MapViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
    var gasPricesDataStore: GasPricesDataStore?
    var locationManager = CLLocationManager()
    var destination: CLLocationCoordinate2D?
    var waypoint: CLLocationCoordinate2D?
    
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
    var stackView: UIStackView! = UIStackView()
    var currentTime: Date?
    var lastTime: Date?
    var lastTimeToCheckSpeed: Date?
    var reacheableSteps = [Direction.Route.Leg.Step]()
    var zoom: Float?
    var viewingAngle: Double?
    var usingCompus: Bool = false
    var directionBtn: UIButton!
    var getDirectionBtn: UIButton?
    var addWayPointBtn: UIButton?
    var startNavBtn: UIButton?
    var cancelBtn: UIButton?
    
    var gasStationsDuringNavigation = GasStations()
    var polylines: [GMSPolyline] = [GMSPolyline]()
    var navigationDirection: Direction?
    var currentStep: Direction.Route.Leg.Step?
    var currentStepIndex: Int?
    var navigationTextView: UITextView = UITextView()
    var searchIsOn: Bool = false
    var stopNavBtn: UIButton?
    var showingStopNavBtn: Bool = false
    var speedLabel: UILabel = UILabel()
    var updateCamera: Bool = true
    var locationBtnHasBeenTapped: Bool = false
    var firstPathDrawn: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myCar = appDelegate!.myCar
        gasPricesDataStore = appDelegate!.gasPricesDataStore
        zoom = 6
        viewingAngle = 0
        
        directionBtn = UIButton(type: .system) as UIButton
        directionBtn.addTarget(self, action: #selector(locationBtnTapped), for: .touchUpInside)
        directionBtn.setImage(UIImage(named: "locationIcon"), for: .normal)
        directionBtn.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        directionBtn.translatesAutoresizingMaskIntoConstraints = false
        
        self.mapView.addSubview(directionBtn!)
        
        directionBtn!.widthAnchor.constraint(equalToConstant: 100).isActive = true
        directionBtn!.heightAnchor.constraint(equalToConstant: 100).isActive = true
        directionBtn!.trailingAnchor.constraint(equalTo: self.mapView.trailingAnchor, constant: 10).isActive = true;
        directionBtn!.bottomAnchor.constraint(equalTo: self.mapView.bottomAnchor, constant: 0).isActive = true;
        
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
        
        //        let chicago = CLLocation(latitude: 41.8781, longitude: -87.6298)
        //        let bloomington = CLLocation(latitude: 40.4842, longitude: -88.9937)
        //        self.drawPath(origin: bloomington, destination: chicago)
    }
    
}

// MARK: location manager functions
extension MapViewController {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else {
            return
        }
        locationManager.startUpdatingLocation()
        locationManager.stopUpdatingHeading()
        mapView.isMyLocationEnabled = true
        mapView.settings.compassButton = true
        mapView.settings.zoomGestures = true
        mapView.settings.tiltGestures = true
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
            self.myCar!.appendSpeed(speed: (self.locationManager.location!.speed * 3600.0 * 0.000621371))
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
        
        if isInNavigation {
            speedLabel.text = "\(round(abs(self.locationManager.location!.speed * 3600.0 * 0.000621371)).description)/mph"
            let hasArrivedToEndOfStep = self.arrivedEndOfStep(currentLocation: self.currentLocation!, endPointInStep: CLLocation(latitude: self.currentStep!.endLocation!.lat!, longitude: self.currentStep!.endLocation!.lng!))
            if hasArrivedToEndOfStep {
                let hasNextStep = self.switchStep()
                if !hasNextStep {
                    // end of destination.
                    self.showEndOfNavigationLabel()
                    usingCompus = false
                }
            }
        }
        
        if updateCamera {
            if self.currentLocation != nil {
                let currentLoc2D = CLLocationCoordinate2D(latitude: self.currentLocation!.coordinate.latitude, longitude: self.currentLocation!.coordinate.longitude)
                mapView.animate(toLocation: currentLoc2D)
            }
            //            mapView.camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: self.zoom!)
        }
        
        clearAllMarkers()
        for keyword in searchKeywords {
            self.fetchGoogleData(forLocation: location, locationName: keyword, searchRadius: self.searchRadius )
        }
        currentLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.mapView.animate(toBearing: newHeading.magneticHeading)
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
        self.gasStationsDuringNavigation.stations?.removeAll()
        let group5 = DispatchGroup()
        group5.enter()
        for step in self.reacheableSteps {
            self.gasPricesDataStore?.getGasPrices(latitude: step.startLocation!.lat!, longitutde: step.startLocation!.lng!, distanceInMiles: 2, gasType: "reg"){
                (response) in
                DispatchQueue.main.async{
                    switch response{
                    case let .success(gasStations):
                        if self.gasStationsDuringNavigation.stations == nil {
                            self.gasStationsDuringNavigation = gasStations
                        } else {
                            self.gasStationsDuringNavigation.stations! += gasStations.stations!
                        }
                        if self.reacheableSteps.last?.startLocation?.lat == step.startLocation?.lat && self.reacheableSteps.last?.startLocation?.lng == step.startLocation?.lng {
                            group5.leave()
                        }
                    case let .failure(error):
                        print(error)
                    }
                }
            }
        }
        
        group5.notify(queue: .main, execute: {
            if let _ = self.gasStationsDuringNavigation.stations{
                
                for station in self.gasStationsDuringNavigation.stations!.sorted(by: {$0.lat!<$1.lat!}) {
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
            

            
            self.gasPricesDataStore?.getGasPrices(latitude: step.endLocation!.lat!, longitutde: step.endLocation!.lng!, distanceInMiles: 2, gasType: "reg"){
                (response) in
                
                switch response{
                case let .success(gasStations):
                    if gasStations.stations != nil{
                        var skipped = 0
                        for gasStationForPrice in gasStations.stations! {
                            let DynamicView=UIView(frame: CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 50, height: 50)))
                            DynamicView.backgroundColor=UIColor.clear
                            var imageViewForPinMarker : UIImageView
                            imageViewForPinMarker  = UIImageView(frame:CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 50, height: 50)))
                            imageViewForPinMarker.image = UIImage(named:"prices")?.withRenderingMode(.alwaysTemplate)
                            imageViewForPinMarker.tintColor = UIColor.green
                            let text = UILabel(frame:CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 40, height: 30)))
                            guard let _ = gasStationForPrice.regPrice else {
                                skipped += 1
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
                            marker.map = self.mapView
                            
                        }
                        print(skipped)
                        
                    }
                    
                    
                case let .failure(error):
                    print(error)
                }
            }
            
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
        })
        
    }
    
    func drawPath(origin: CLLocation, destination: CLLocation) {
        self.reacheableSteps.removeAll()
        googleClient.getDirection(origin: origin, destination: destination) { (directionsResult) in
            switch directionsResult {
            case let .success(direction):
                self.navigationDirection = direction
                if direction.routes!.count > 0 {
                    // check if start points of each leg is reacheable
                    let group5 = DispatchGroup()
                    if let steps = direction.routes![0].legs![0].steps {
                        group5.enter()
                        for step in steps {
                            let route = step.polyline!.points
                            let path: GMSPath = GMSPath(fromEncodedPath: route!)!
                            let polyline = GMSPolyline(path: path)
                            self.polylines.append(polyline)
                            polyline.strokeWidth = 4
                            polyline.strokeColor = .blue
                            polyline.geodesic = true
                            polyline.map = self.mapView
                            let destLat = step.endLocation!.lat
                            let destLng = step.endLocation!.lng
                            
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
                            
                            self.googleClient.getDistance(origin: self.currentLocation!, destination: destination, completion: { (distanceResult) in
                                DispatchQueue.main.async{
                                    switch distanceResult {
                                    case let .success(distance):
                                        if let distanceVal = distance.rows![0].elements![0].distance!.value {
                                            let reachableDistanceInMiles = self.myCar!.getFuelRemaining() * self.myCar!.mpgHwy * 1.600934 * 1000
                                            // if the start location of a leg is reacheable, put into the reacheableLegs array
                                            if distanceVal < reachableDistanceInMiles {
                                                self.reacheableSteps.append(step)
                                            }
                                            if step.endLocation?.lat == direction.routes![0].legs![0].steps?.last?.endLocation?.lat && step.endLocation?.lng == direction.routes![0].legs![0].steps?.last?.endLocation?.lng {
                                                group5.leave()
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
                            self.setMarkersWhileNavigation()
                        })
                    } else {
                        print("No routes to that destination")
                    }
                case let .failure(error):
                    print(error)
                }
            }
        }
    }
    
    func drawPath(origin: CLLocation, destination: CLLocation, waypoint: CLLocation) {
        for polyline in polylines {
            polyline.map = nil
        }
        self.reacheableSteps.removeAll()
        googleClient.getDirection(origin: origin, destination: destination, waypoint: waypoint, completion: { (directionsResult) in
            switch directionsResult {
            case let .success(direction):
                self.navigationDirection = direction
                if direction.routes!.count > 0 {
                    if let steps = direction.routes![0].legs![0].steps {
                        for step in steps {
                            let route = step.polyline!.points
                            let path: GMSPath = GMSPath(fromEncodedPath: route!)!
                            let polyline = GMSPolyline(path: path)
                            polyline.strokeWidth = 4
                            polyline.strokeColor = .blue
                            polyline.geodesic = true
                            polyline.map = self.mapView
                        }
                    }
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
        controller.selectedTypes = searchKeywords
        controller.delegate = self
    }
    
}

// MARK: GMS Auto Complete Functions
extension MapViewController: GMSAutocompleteViewControllerDelegate {
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        let camera = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude, longitude: place.coordinate.longitude, zoom: 15.0)
        self.mapView.animate(to: camera)
        view = self.mapView
        
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        marker.title = place.name
        marker.snippet = place.formattedAddress
        marker.map = self.mapView
        
        
        
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
        if !self.firstPathDrawn {
            self.destination = marker.position
            self.getDirectionBtn = UIButton(type: .system)
            self.getDirectionBtn!.frame = CGRect(x: 150, y: 100, width: 150, height: 30)
            self.getDirectionBtn!.setTitle("Get Direction", for: .normal)
            self.getDirectionBtn!.backgroundColor = UIColor(red:0.00, green:0.53, blue:1.00, alpha:1.0)
            self.getDirectionBtn!.layer.cornerRadius = 5
            self.getDirectionBtn!.setTitleColor(.white, for: .normal)
            self.getDirectionBtn!.addTarget(self, action: #selector(getDirectionBtnTapped), for: .touchUpInside)
        } else {
            self.waypoint = marker.position
            self.addWayPointBtn = UIButton(type: .system)
            self.addWayPointBtn!.frame = CGRect(x: 150, y: 100, width: 150, height: 30)
            self.addWayPointBtn!.setTitle("Add Waypoint", for: .normal)
            self.addWayPointBtn!.backgroundColor = UIColor(red: 0, green: 0.8275, blue: 0.5922, alpha: 1.0)
            self.addWayPointBtn!.layer.cornerRadius = 5
            self.addWayPointBtn!.setTitleColor(.white, for: .normal)
            self.addWayPointBtn!.addTarget(self, action: #selector(addWaypointBtntapped), for: .touchUpInside)
        }
        self.cancelBtn = UIButton(type: .system)
        self.cancelBtn!.frame = CGRect(x: 150, y: 100, width: 150, height: 30)
        self.cancelBtn!.setTitle("Cancel", for: .normal)
        self.cancelBtn!.backgroundColor = UIColor(red:1.00, green:0.30, blue:0.00, alpha:1.0)
        self.cancelBtn!.layer.cornerRadius = 5
        self.cancelBtn!.setTitleColor(.white, for: .normal)
        self.cancelBtn!.addTarget(self, action: #selector(cancelBtnTapped), for: .touchUpInside)
        if self.getDirectionBtn != nil {
            self.getDirectionBtn!.translatesAutoresizingMaskIntoConstraints = false
        }
        if self.addWayPointBtn != nil {
            self.addWayPointBtn!.translatesAutoresizingMaskIntoConstraints = false
        }
        self.cancelBtn!.translatesAutoresizingMaskIntoConstraints = false
        if !firstPathDrawn {
            self.getDirectionBtn!.widthAnchor.constraint(equalToConstant: 140).isActive = true
            self.getDirectionBtn!.heightAnchor.constraint(equalToConstant: 50).isActive = true
        } else {
            self.addWayPointBtn!.widthAnchor.constraint(equalToConstant: 140).isActive = true
            self.addWayPointBtn!.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
        self.cancelBtn!.widthAnchor.constraint(equalToConstant: 140).isActive = true
        self.cancelBtn!.heightAnchor.constraint(equalToConstant: 50).isActive = true
        // adding buttons to the subview
        for view in self.stackView.subviews {
            view.removeFromSuperview()
        }
        if !firstPathDrawn {
            self.stackView.addArrangedSubview(self.getDirectionBtn!)
        } else {
            self.stackView.addArrangedSubview(self.addWayPointBtn!)
        }
        self.stackView.addArrangedSubview(self.cancelBtn!)
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
        print("tapped")
        if isInNavigation {
            if showingStopNavBtn == false {
                stopNavBtn = UIButton(type: .system)
                stopNavBtn!.frame = CGRect(x: 0, y: 0, width: 100, height: 30)
                stopNavBtn!.setTitle("Exit", for: .normal)
                stopNavBtn!.backgroundColor = UIColor(red:1.00, green:0.30, blue:0.00, alpha:1.0)
                stopNavBtn!.layer.cornerRadius = 5
                stopNavBtn!.setTitleColor(.white, for: .normal)
                stopNavBtn!.addTarget(self, action: #selector(stopNavBtnTapped), for: .touchUpInside)
                
                let lbl2 = UILabel(frame: CGRect.init(x: lbl1.frame.origin.x , y: lbl1.frame.origin.y+lbl1.frame.size.height + 3, width: view.frame.size.width - 16, height: 15))
                lbl2.text = placeMarker.place.address
                lbl2.font = UIFont.systemFont(ofSize: 12, weight: .medium)
                view.addSubview(lbl2)
                
                let lbl3 = UILabel(frame: CGRect.init(x: lbl2.frame.origin.x , y: lbl2.frame.origin.y+lbl2.frame.size.height + 3, width: view.frame.size.width - 16, height: 15))
                lbl3.text = (placeMarker.place.openingHours?.isOpen! == true) ? "Open":"Closed"
                lbl3.font = UIFont.systemFont(ofSize: 12, weight: .thin)
                lbl3.textColor = (placeMarker.place.openingHours?.isOpen! == true) ? UIColor.red:UIColor.green
                view.addSubview(lbl3)
                
                let placedetails = UIButton(type: .system)
                placedetails.frame = CGRect(x: lbl3.frame.origin.x, y: lbl3.frame.origin.y+lbl3.frame.size.height + 5 , width: view.frame.size.width - 16, height: 30)
                placedetails.setTitle("Details", for: .normal)
                placedetails.backgroundColor = UIColor(red:0.00, green:0.53, blue:1.00, alpha:1.0)
                placedetails.layer.cornerRadius = 5
                placedetails.setTitleColor(.white, for: .normal)
                placedetails.addTarget(self, action: #selector(self.placeDetailsNav), for: .touchUpInside)
                view.addSubview(placedetails)
                
                //        let lbl1 = UILabel(frame: CGRect.init(x: 8, y: 8, width: view.frame.size.width - 16, height: 15))
                //        lbl1.text = "Hi there!"
                //        view.addSubview(lbl1)
                //
                //        let lbl2 = UILabel(frame: CGRect.init(x: lbl1.frame.origin.x, y: lbl1.frame.origin.y + lbl1.frame.size.height + 3, width: view.frame.size.width - 16, height: 15))
                //        lbl2.text = "I am a custom info window."
                //        lbl2.font = UIFont.systemFont(ofSize: 14, weight: .light)
                //        view.addSubview(lbl2)
                
                return view
                
            }
            return nil
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
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        self.zoom = position.zoom
        self.viewingAngle = position.viewingAngle
    }
    
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        if gesture {
            updateCamera = false
            locationBtnHasBeenTapped = false
            locationManager.stopUpdatingLocation()
            locationManager.stopUpdatingHeading()
        }
    }
    
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        let view = UIView(frame: CGRect.init(x: 0, y: 0, width: 200, height: 100))
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 6
        if let place = marker as? PlaceMarker {
            let lbl1 = UILabel(frame: CGRect.init(x: 8, y: 8, width: view.frame.size.width - 16, height: 15))
            lbl1.text = place.place.name
            lbl1.font = UIFont.systemFont(ofSize: 14, weight: .heavy)
            view.addSubview(lbl1)
            
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
            for view in self.stackView.subviews {
                view.removeFromSuperview()
            }
            self.stackView!.removeFromSuperview()
            self.cancelBtn = nil
            self.getDirectionBtn = nil
            self.startNavBtn = nil
            
            return view
            
        }
        return nil
    }
    
}

// MARK: needs to be changed - Sanket
extension MapViewController {
    
    func addingSearchAndFilterButtonToRightNavigation(){
        let imgforsearch = UIImage(named: "search")!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        let imgforfilter = UIImage(named: "filter")!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        let searchButton = UIBarButtonItem(image: imgforsearch, style: .plain, target: self, action: #selector(searchBtnTapped))
        let forfilter = UIBarButtonItem(image: imgforfilter, style: .plain, target: self, action: #selector(filterClicked))
        navigationItem.setRightBarButtonItems([searchButton,forfilter], animated: true)
    }
    
}

// MARK: Custom functions
extension MapViewController {
    
    @objc func settingsTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showCarSummary", sender: self)
    }
    
    private func showStartNavBtn() {
        self.stackView!.removeFromSuperview()
        // remove buttons from the view
        for view in self.stackView.subviews {
            view.removeFromSuperview()
        }
        self.stackView!.removeFromSuperview()
        self.cancelBtn = nil
        self.getDirectionBtn = nil
        self.startNavBtn = nil
        
        self.startNavBtn = UIButton(type: .system)
        startNavBtn!.frame = CGRect(x: 150, y: 100, width: 150, height: 30)
        startNavBtn!.setTitle("Start Navigation", for: .normal)
        startNavBtn!.backgroundColor = UIColor(red:0.00, green:0.53, blue:1.00, alpha:1.0)
        startNavBtn!.layer.cornerRadius = 5
        startNavBtn!.setTitleColor(.white, for: .normal)
        startNavBtn!.addTarget(self, action: #selector(startNavBtnTapped), for: .touchUpInside)
        
        self.cancelBtn = UIButton(type: .system)
        cancelBtn!.frame = CGRect(x: 150, y: 100, width: 150, height: 30)
        cancelBtn!.setTitle("Cancel", for: .normal)
        cancelBtn!.backgroundColor = UIColor(red:1.00, green:0.30, blue:0.00, alpha:1.0)
        cancelBtn!.layer.cornerRadius = 5
        cancelBtn!.setTitleColor(.white, for: .normal)
        cancelBtn!.addTarget(self, action: #selector(cancelBtnTapped), for: .touchUpInside)
        
        startNavBtn!.translatesAutoresizingMaskIntoConstraints = false
        cancelBtn!.translatesAutoresizingMaskIntoConstraints = false
        
        startNavBtn!.widthAnchor.constraint(equalToConstant: 140).isActive = true
        startNavBtn!.heightAnchor.constraint(equalToConstant: 50).isActive = true
        cancelBtn!.widthAnchor.constraint(equalToConstant: 140).isActive = true
        cancelBtn!.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        // adding buttons to the subview
        self.stackView.addArrangedSubview(self.startNavBtn!)
        self.stackView.addArrangedSubview(self.cancelBtn!)
        self.stackView!.axis = .vertical
        self.stackView!.spacing = 30
        // enables auto layout for buttons
        self.stackView!.translatesAutoresizingMaskIntoConstraints = false
        self.mapView.addSubview(stackView!)
        
        self.stackView!.centerXAnchor.constraint(equalTo: self.mapView.centerXAnchor).isActive = true
        self.stackView!.bottomAnchor.constraint(lessThanOrEqualTo: self.mapView.bottomAnchor, constant: -50).isActive = true
    }
    
    @objc func getDirectionBtnTapped(_ sender: UIButton) {
        self.firstPathDrawn = true
        let destination = CLLocation(latitude: self.destination!.latitude, longitude: self.destination!.longitude)
        
        let currentLocation2D = CLLocationCoordinate2D(latitude: self.currentLocation!.coordinate.latitude, longitude: self.currentLocation!.coordinate.longitude)
        let bounds = GMSCoordinateBounds(coordinate: currentLocation2D, coordinate: self.destination!)
        var insets = UIEdgeInsets()
        insets.bottom = 50
        insets.top = 50
        insets.right = 50
        insets.left = 50
        let camera = self.mapView.camera(for: bounds, insets: insets)!
        self.mapView.animate(to: camera)
        self.drawPath(origin: currentLocation!, destination: destination)
        showStartNavBtn()
    }
    
    @objc func addWaypointBtntapped(_ sender: UIButton) {
        let destination = CLLocation(latitude: self.destination!.latitude, longitude: self.destination!.longitude)
        let waypoint = CLLocation(latitude: self.waypoint!.latitude, longitude: self.waypoint!.longitude)
        
        let currentLocation2D = CLLocationCoordinate2D(latitude: self.currentLocation!.coordinate.latitude, longitude: self.currentLocation!.coordinate.longitude)
        let bounds = GMSCoordinateBounds(coordinate: currentLocation2D, coordinate: self.destination!)
        var insets = UIEdgeInsets()
        insets.bottom = 50
        insets.top = 50
        insets.right = 50
        insets.left = 50
        let camera = self.mapView.camera(for: bounds, insets: insets)!
        self.mapView.animate(to: camera)
        self.drawPath(origin: currentLocation!, destination: destination, waypoint: waypoint)
        showStartNavBtn()
    }
    
    @objc func startNavBtnTapped(_ sender: UIButton) {
        UIApplication.shared.isIdleTimerDisabled = true
        print("startNavBtnTapped")
        for view in self.stackView.subviews {
            view.removeFromSuperview()
        }
        self.speedLabel.text = "\(round(abs(self.locationManager.location!.speed * 3600.0 * 0.000621371)).description)/mph"
        self.speedLabel.textAlignment = .center
        self.speedLabel.backgroundColor = UIColor.black
        self.speedLabel.alpha = 0.8
        self.speedLabel.layer.cornerRadius = 5
        self.speedLabel.textColor = UIColor.white
        
        self.mapView.addSubview(self.speedLabel)
        
        self.zoom = 18
        self.viewingAngle = 45
        self.isInNavigation = true
        self.usingCompus = true
        self.currentStep = self.navigationDirection!.routes![0].legs![0].steps![0]
        
        self.navigationTextView.text = self.currentStep?.htmlInstructions!.html2String
        self.navigationTextView.backgroundColor = UIColor(red:0.00, green:0.53, blue:1.00, alpha:1.0)
        self.navigationTextView.textColor = UIColor.white
        self.navigationTextView.alpha = 0.8
        self.navigationTextView.layer.cornerRadius = 5
        self.navigationTextView.font = UIFont(name: self.navigationTextView.font!.fontName, size: 18)
        
        self.mapView.addSubview(self.navigationTextView)
        // constraints for navigationTextView
        self.navigationTextView.translatesAutoresizingMaskIntoConstraints = false
        self.navigationTextView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        self.navigationTextView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        self.navigationTextView.leadingAnchor.constraint(equalTo: self.mapView.leadingAnchor).isActive = true
        self.navigationTextView.bottomAnchor.constraint(equalTo: self.mapView.bottomAnchor).isActive = true
        // constraints for speedLabel
        self.speedLabel.translatesAutoresizingMaskIntoConstraints = false
        self.speedLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        self.speedLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
        self.speedLabel.leadingAnchor.constraint(equalTo: self.mapView.leadingAnchor).isActive = true
        self.speedLabel.bottomAnchor.constraint(equalTo: self.navigationTextView.topAnchor, constant: -10).isActive = true
        
        currentStepIndex = 0
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        let camera = GMSCameraPosition.camera(withLatitude: currentLocation!.coordinate.latitude, longitude: currentLocation!.coordinate.longitude, zoom: self.zoom!, bearing: 0, viewingAngle: self.viewingAngle!)
        self.mapView.animate(to: camera)
    }
    
    @objc func stopNavBtnTapped(_ sender: UIButton) {
        self.firstPathDrawn = false
        UIApplication.shared.isIdleTimerDisabled = false
        self.navigationTextView.removeFromSuperview()
        self.speedLabel.removeFromSuperview()
        self.stopNavBtn!.removeFromSuperview()
        self.isInNavigation = false
        self.mapView.clear()
        self.zoom = 15
        let camera = GMSCameraPosition.camera(withLatitude: self.currentLocation!.coordinate.latitude, longitude: self.currentLocation!.coordinate.longitude, zoom: zoom!)
        self.mapView.animate(to: camera)
    }
    
    @objc func cancelBtnTapped(_ sender: UIButton) {
        self.firstPathDrawn = false
        locationManager.startUpdatingLocation()
        print("cancelbtn tapped")
        for view in self.stackView.subviews {
            view.removeFromSuperview()
        }
        self.mapView.clear()
        let camera = GMSCameraPosition.camera(withLatitude: self.currentLocation!.coordinate.latitude, longitude: self.currentLocation!.coordinate.longitude, zoom: zoom!)
        self.mapView.animate(to: camera)
        self.stackView!.removeFromSuperview()
        for keyword in searchKeywords{
            self.fetchGoogleData(forLocation: currentLocation!, locationName: keyword, searchRadius: self.searchRadius )
        }
    }
    
    @objc func locationBtnTapped(_ sender: UIButton) {
        self.zoom = 16
        if isInNavigation {
            self.viewingAngle = 45
            self.zoom = 18
        }
        let camera = GMSCameraPosition.camera(withLatitude: self.currentLocation!.coordinate.latitude, longitude: self.currentLocation!.coordinate.longitude, zoom: self.zoom!, bearing: 0, viewingAngle: self.viewingAngle!)
        mapView.animate(to: camera)
        self.locationManager.startUpdatingLocation()
        if locationBtnHasBeenTapped {
            self.locationManager.startUpdatingHeading()
        } else {
            self.locationManager.stopUpdatingHeading()
        }
        locationBtnHasBeenTapped = !locationBtnHasBeenTapped
        updateCamera = true
    }
    
    //    part of expandable search bar
    @objc func searchBtnTapped() {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        present(autocompleteController, animated: true, completion: nil)
    }
    
    
    // returns true if the distance between the current location to the end point of the current step in the navigation mode.
    private func arrivedEndOfStep (currentLocation: CLLocation, endPointInStep: CLLocation) -> Bool {
        let distanceInMeters = currentLocation.distance(from: endPointInStep)
        if distanceInMeters < 20 {
            return true
        } else {
            return false
        }
        
        @objc func locationBtnTapped(_ sender: UIButton) {
            let camera = GMSCameraPosition.camera(withLatitude: self.currentLocation!.coordinate.latitude, longitude: self.currentLocation!.coordinate.longitude, zoom: 16)
            self.mapView.camera = camera
            self.usingCompus = !self.usingCompus
        }
        
        //    part of expandable search bar
        @objc func toggle() {
            let autocompleteController = GMSAutocompleteViewController()
            autocompleteController.delegate = self
            locationManager.stopUpdatingLocation()
            present(autocompleteController, animated: true, completion: nil)
        }
        
    }
    
    @objc func placeDetailsNav(_ sender: UIButton) {
        self.performSegue(withIdentifier: "GoToDetailsContoller", sender:self)
    }
    
}

//part of expandable search bar
class ExpandableView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        
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
    
    extension Data {
        var html2AttributedString: NSAttributedString? {
            do {
                return try NSAttributedString(data: self, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
            } catch {
                print("error:", error)
                return  nil
            }
        }
        var html2String: String {
            return html2AttributedString?.string ?? ""
        }
    }
    
    extension String {
        var html2AttributedString: NSAttributedString? {
            return Data(utf8).html2AttributedString
        }
        var html2String: String {
            return html2AttributedString?.string ?? ""
        }
}



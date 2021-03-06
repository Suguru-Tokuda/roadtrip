import UIKit
import GoogleMaps
import GooglePlaces
import CoreLocation


var searchLocations:[FilterKeywordWithImage] = [FilterKeywordWithImage(key: "pizza", name: "Pizza", icon: #imageLiteral(resourceName: "pizza")),
                                                FilterKeywordWithImage(key: "burger", name: "Burger", icon: #imageLiteral(resourceName: "burger")),
                                                FilterKeywordWithImage(key: "food", name: "Food", icon: #imageLiteral(resourceName: "Food")),
                                                FilterKeywordWithImage(key: "noodles", name: "Chinese", icon: #imageLiteral(resourceName: "Chinese")),
                                                FilterKeywordWithImage(key: "mexican", name: "Mexican", icon: #imageLiteral(resourceName: "Mexican")),
                                                FilterKeywordWithImage(key: "gas_station", name: "AGas Station", icon: UIImage.imageForGasStation(price: 2.5, color : UIColor(red: 0.0863, green: 0.6, blue: 0, alpha: 1.0)))]

class MapViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    let appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate
    var gasPricesDataStore: GasPricesDataStore?
    var locationManager = CLLocationManager()
    var destination: CLLocation?
    var waypoint: CLLocation?
    var waypoints: [CLLocation] = [CLLocation]()
    
    @IBOutlet weak var mapView: GMSMapView!
    
    lazy var googleClient = GoogleClient()
    var myCar: Car?
    var currentLocation: CLLocation?
    var lastLocation: CLLocation?
    var searchKeywords:[String] = []
    var searchRadius : Int = 1000
    let searchBar = UISearchBar()
    var isInNavigation: Bool = false
    var markers=[String:[PlaceMarker]]()
    var buttonsStackView: UIStackView! = UIStackView()
    var travelInfoStackView: UIStackView! = UIStackView()
    var currentTime: Date?
    var lastTime: Date?
    var lastTimeToCheckSpeed: Date?
    var reacheableSteps = [Direction.Route.Leg.Step]()
    var zoom: Float?
    var viewingAngle: Double?
    var usingCompus: Bool = false
    var locationBtn: UIButton!
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
    var fuelRemainingTextView: UITextView = UITextView()
    var searchIsOn: Bool = false
    var stopNavBtn: UIButton?
    var showingStopNavBtn: Bool = false
    var speedLabel: UILabel = UILabel()
    var distanceLabel: UILabel = UILabel()
    var updateCamera: Bool = true
    var locationBtnHasBeenTapped: Bool = false
    var firstPathDrawn: Bool = false
    var isRestaurant: Bool = false
    var placedetail: PlaceDetail?
    var markerCoord = [[Double:Double]]()
    var gasStationWithin = 3.0
    var gastype:String{
        switch myCar?.gasType {
        case "Unleaded" :
            return "reg"
        case "Plus":
            return "mid"
        case "Premium":
            return "pre"
        default:
            return "reg"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lastTime = Date()
        lastTimeToCheckSpeed = Date()
        myCar = appDelegate!.myCar
        gasPricesDataStore = appDelegate!.gasPricesDataStore
        zoom = 6
        viewingAngle = 0
        
        locationBtn = UIButton(type: .system) as UIButton
        locationBtn.addTarget(self, action: #selector(locationBtnTapped), for: .touchUpInside)
        locationBtn.setImage(UIImage(named: "locationIcon"), for: .normal)
        locationBtn.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        locationBtn.translatesAutoresizingMaskIntoConstraints = false
        
        self.mapView.addSubview(locationBtn!)
        
        locationBtn!.widthAnchor.constraint(equalToConstant: 100).isActive = true
        locationBtn!.heightAnchor.constraint(equalToConstant: 100).isActive = true
        locationBtn!.trailingAnchor.constraint(equalTo: self.mapView.trailingAnchor, constant: 10).isActive = true;
        locationBtn!.bottomAnchor.constraint(equalTo: self.mapView.bottomAnchor, constant: 0).isActive = true;
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
        locationManager.stopUpdatingHeading()
        locationManager.startUpdatingLocation()
        mapView.isMyLocationEnabled = true
        mapView.settings.compassButton = true
        mapView.settings.zoomGestures = true
        mapView.settings.tiltGestures = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if lastLocation == nil {
            lastLocation = locations.first
        }
        
        guard let location = locations.first else {
            return
        }
        
        /*
         Every 5 seconds, check the current speed and put the speed into the speeds, array of Double
         */
        if abs(lastTimeToCheckSpeed!.timeIntervalSinceNow) >= 5.0 {
            self.myCar!.appendSpeed(speed: (self.locationManager.location!.speed * 3600.0 * 0.000621371))
            lastTimeToCheckSpeed = Date() // assiging the current time
        }
        
        /*
         If 5 minutes have passed, it gets the distance between the current and last locations.
         Then it will reduce the fuel remaining.
         */
        if abs(lastTime!.timeIntervalSinceNow) >= 2.0 * 30 {
            googleClient.getDistance(origin: lastLocation!, destination: location) { (distanceResult) in
                switch distanceResult {
                case let .success(distance):
                    let distanceParam = distance.rows![0].elements![0].distance!.value! / 1000 * 0.621371
                    self.lastLocation = self.currentLocation
                    self.currentLocation = location
                    self.myCar!.consumeFuel(speed: self.myCar!.getAverageSpeed(), distance: distanceParam)
                    self.fuelRemainingTextView.text = "\(self.myCar!.getFuelRemaining())/\(self.myCar!.fuelCapacity) gals"
                    self.myCar!.resetSpeeds()
                    self.lastLocation = self.currentLocation
                    self.lastTime = Date()
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
        gasStationsDuringNavigation = GasStations()
        markerCoord = [[Double:Double]]()
        for step in self.reacheableSteps {
            DispatchQueue.main.async{
                self.gasPricesDataStore?.getGasPrices(latitude: step.startLocation!.lat!, longitutde: step.startLocation!.lng!, distanceInMiles: self.gasStationWithin, gasType: self.gastype){
                    (response) in
                    switch response{
                    case let .success(gasStations):
                        if gasStations.stations != nil{
                            var avggasprice = 0.0
                            var stationcount = 0.0
                            for gasStationForPrice in gasStations.stations! {
                                if ((gasStationForPrice.regPrice != nil) && self.gastype == "reg")
                                    || ((gasStationForPrice.midPrice != nil) && self.gastype == "mid")
                                    || ((gasStationForPrice.prePrice != nil) && self.gastype == "pre")  {
                                    stationcount += 1
                                    avggasprice += (self.gastype == "pre") ? gasStationForPrice.prePrice! : (self.gastype == "mid") ? gasStationForPrice.midPrice! : gasStationForPrice.regPrice!
                                }
                            }
                            
                            avggasprice /= stationcount
                            for gasStationForPrice in gasStations.stations! {
                                
                                if !self.markerCoord.contains([gasStationForPrice.lat!:gasStationForPrice.lng!]){
                                    self.markerCoord.append([gasStationForPrice.lat!:gasStationForPrice.lng!])
                                    if ((gasStationForPrice.regPrice == nil) && self.gastype == "reg")
                                        || ((gasStationForPrice.midPrice == nil) && self.gastype == "mid")
                                        || ((gasStationForPrice.prePrice == nil) && self.gastype == "pre")  {
                                        continue
                                    }
                                    let gasprice = (self.gastype == "reg") ? gasStationForPrice.regPrice! : (self.gastype == "mid") ? gasStationForPrice.midPrice! : gasStationForPrice.prePrice!
                                    if gasprice >= (avggasprice - 0.1){
                                        continue
                                    }
                                    let marker = GMSMarker()
                                    marker.title = gasStationForPrice.station!
                                    marker.position = CLLocationCoordinate2DMake(gasStationForPrice.lat!, gasStationForPrice.lng!)
                                    marker.groundAnchor = CGPoint(x: 0.5, y: 1)
                                    marker.appearAnimation = .pop
                                    marker.icon = UIImage.imageForGasStation(price: gasprice, color: (gasprice > (avggasprice * 0.95)) ? .red : UIColor(red: 0.0863, green: 0.6, blue: 0, alpha: 1.0))
                                    marker.map = self.mapView
                                }
                            }
                        }
                    case let .failure(error):
                        print(error)
                    }
                }
            }
            
            self.gasPricesDataStore?.getGasPrices(latitude: step.endLocation!.lat!, longitutde: step.endLocation!.lng!, distanceInMiles: self.gasStationWithin, gasType: self.gastype){
                (response) in
                
                switch response{
                case let .success(gasStations):
                    if gasStations.stations != nil{
                        var avggasprice = 0.0
                        var stationcount = 0.0
                        for gasStationForPrice in gasStations.stations! {
                            if ((gasStationForPrice.regPrice != nil) && self.gastype == "reg")
                                || ((gasStationForPrice.midPrice != nil) && self.gastype == "mid")
                                || ((gasStationForPrice.prePrice != nil) && self.gastype == "pre")  {
                                stationcount += 1
                                avggasprice += (self.gastype == "pre") ? gasStationForPrice.prePrice! : (self.gastype == "mid") ? gasStationForPrice.midPrice! : gasStationForPrice.regPrice!
                            }
                        }
                        avggasprice /= stationcount
                        for gasStationForPrice in gasStations.stations! {
                            if !self.markerCoord.contains([gasStationForPrice.lat!:gasStationForPrice.lng!]){
                                self.markerCoord.append([gasStationForPrice.lat!:gasStationForPrice.lng!])
                                if ((gasStationForPrice.regPrice == nil) && self.gastype == "reg")
                                    || ((gasStationForPrice.midPrice == nil) && self.gastype == "mid")
                                    || ((gasStationForPrice.prePrice == nil) && self.gastype == "pre")  {
                                    continue
                                }
                                let gasprice = (self.gastype == "reg") ? gasStationForPrice.regPrice! : (self.gastype == "mid") ? gasStationForPrice.midPrice! : gasStationForPrice.prePrice!
                                if gasprice >= (avggasprice - 0.1){
                                    continue
                                }
                                let marker = GMSMarker()
                                marker.title = gasStationForPrice.station!
                                marker.position = CLLocationCoordinate2DMake(gasStationForPrice.lat!, gasStationForPrice.lng!)
                                marker.groundAnchor = CGPoint(x: 0.5, y: 1)
                                marker.appearAnimation = .pop
                                marker.icon = UIImage.imageForGasStation(price: gasprice, color: (gasprice > (avggasprice * 0.95)) ? .red : UIColor(red: 0.0863, green: 0.6, blue: 0, alpha: 1.0))
                                marker.map = self.mapView
                            }
                        }
                    }
                case let .failure(error):
                    print(error)
                }
            }
        }  
    }
    
    func fetchGoogleData(forLocation: CLLocation, locationName: String, searchRadius: Int) {
        if locationName == "gas_station"{
            markerCoord.removeAll()
            self.gasPricesDataStore?.getGasPrices(latitude: forLocation.coordinate.latitude, longitutde: forLocation.coordinate.longitude, distanceInMiles: self.gasStationWithin, gasType: "reg"){
                (response) in
                switch response{
                case let .success(gasStations):
                    if gasStations.stations != nil{
                        var avggasprice = 0.0
                        var stationcount = 0.0
                        for gasStationForPrice in gasStations.stations! {
                            if ((gasStationForPrice.regPrice != nil) && self.gastype == "reg")
                                || ((gasStationForPrice.midPrice != nil) && self.gastype == "mid")
                                || ((gasStationForPrice.prePrice != nil) && self.gastype == "pre")  {
                                stationcount += 1
                                avggasprice += (self.gastype == "pre") ? gasStationForPrice.prePrice! : (self.gastype == "mid") ? gasStationForPrice.midPrice! : gasStationForPrice.regPrice!
                            }
                        }
                        for gasStationForPrice in gasStations.stations! {
                            if !self.markerCoord.contains([gasStationForPrice.lat!:gasStationForPrice.lng!]){
                                self.markerCoord.append([gasStationForPrice.lat!:gasStationForPrice.lng!])
                                if ((gasStationForPrice.regPrice == nil) && self.gastype == "reg")
                                    || ((gasStationForPrice.midPrice == nil) && self.gastype == "mid")
                                    || ((gasStationForPrice.prePrice == nil) && self.gastype == "pre")  {
                                    continue
                                }
                                let gasprice = (self.gastype == "reg") ? gasStationForPrice.regPrice! : (self.gastype == "mid") ? gasStationForPrice.midPrice! : gasStationForPrice.prePrice!
                                
                                let marker = GMSMarker()
                                marker.position = CLLocationCoordinate2DMake(gasStationForPrice.lat!, gasStationForPrice.lng!)
                                marker.groundAnchor = CGPoint(x: 0.5, y: 1)
                                marker.appearAnimation = .pop
                                marker.title = gasStationForPrice.station
                                marker.icon = UIImage.imageForGasStation(price: gasprice, color: (gasprice > (avggasprice * 0.95)) ? .red : UIColor(red: 0.0863, green: 0.6, blue: 0, alpha: 1.0))
                                marker.map = self.mapView
                                let place = Place(geometry: Place.Location(location: Place.Location.LatLong(latitude: gasStationForPrice.lat!, longitude: gasStationForPrice.lng!)), name: gasStationForPrice.station!, openingHours: nil, photos: nil, placeID: "gasstation", types: [], address: "")
                                let placemarker = PlaceMarker(place: place)
                                self.addMarker(markerType: locationName, marker: placemarker)
                            }
                        }
                    }
                case let .failure(error):
                    print(error)
                }
            }
        } else {
            let group1 = DispatchGroup()
            group1.enter()
            googleClient.getGooglePlacesData(forKeyword: locationName, location: forLocation, withinMeters: searchRadius) { (response) in
                DispatchQueue.main.sync{
                    let places = response.results
                    for place in places {
                        let marker = PlaceMarker(place: place)
                        marker.title = place.name
                        marker.snippet = "The place is \(place.openingHours?.isOpen == true ? "open" : "closed")"
                        if let key = searchLocations.first(where: {$0.key == locationName}) {
                            marker.icon = key.icon
                            marker.map = self.mapView
                        }
                        else{
                            return
                        }
                        self.addMarker(markerType: locationName, marker: marker)
                    }
                    if pagetoken == ""{
                        return
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
                            if let key = searchLocations.first(where: {$0.key == locationName}) {
                                marker.icon = key.icon
                                marker.map = self.mapView
                            }
                            else{
                                return
                            }
                            self.addMarker(markerType: locationName, marker: marker)
                        }
                        if pagetoken == ""{
                            return
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
                            if let key = searchLocations.first(where: {$0.key == locationName}) {
                                marker.icon = key.icon
                                marker.map = self.mapView
                            }
                            else{
                                return
                            }
                            self.addMarker(markerType: locationName, marker: marker)
                        }
                    }
                }
            })
        }
    }
    
    func drawPath(origin: CLLocation, destination: CLLocation) {
        for polyline in polylines {
            polyline.map = nil
        }
        self.reacheableSteps.removeAll()
        googleClient.getDirection(origin: origin, destination: destination) { (directionsResult) in
            switch directionsResult {
            case let .success(direction):
                self.navigationDirection = direction
                if direction.routes!.count > 0 {
                    // check if start points of each leg is reacheable
                    let group5 = DispatchGroup()
                    var fastestLegIndex = 0
                    if let legs = direction.routes![0].legs {
                        var fastestLeg = legs[0]
                        for index in 0..<legs.count{
                            if legs[index].duration!.value! < fastestLeg.duration!.value! {
                                fastestLeg = legs[index]
                                fastestLegIndex = index
                            }
                        }
                    }
                    self.showTravelInfo(leg: direction.routes![0].legs![fastestLegIndex])
                    if let steps = direction.routes![0].legs![fastestLegIndex].steps {
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
                            let destination = CLLocation(latitude: destLat!, longitude: destLng!)
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
    
    func drawPath(origin: CLLocation, destination: CLLocation, waypoints: [CLLocation]) {
        for polyline in polylines {
            polyline.map = nil
        }
        self.reacheableSteps.removeAll()
        googleClient.getDirection(origin: origin, destination: destination, waypoints: waypoints, completion: { (directionsResult) in
            switch directionsResult {
            case let .success(direction):
                self.navigationDirection = direction
                if direction.routes!.count > 0 {
                    var fastestLegIndex = 0
                    if let legs = direction.routes![0].legs {
                        var fastestLeg = legs[0]
                        for index in 0..<legs.count{
                            if legs[index].duration!.value! < fastestLeg.duration!.value! {
                                fastestLeg = legs[index]
                                fastestLegIndex = index
                            }
                        }
                    }
                    self.showTravelInfo(leg: direction.routes![0].legs![fastestLegIndex])
                    if let steps = direction.routes![0].legs![fastestLegIndex].steps {
                        for step in steps {
                            let route = step.polyline!.points
                            let path: GMSPath = GMSPath(fromEncodedPath: route!)!
                            let polyline = GMSPolyline(path: path)
                            self.polylines.append(polyline)
                            polyline.strokeWidth = 4
                            polyline.strokeColor = .blue
                            polyline.geodesic = true
                            polyline.map = self.mapView
                        }
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
                if key == "gas_station"{
                    mapView.clear()
                    clearAllMarkers()
                }
                else{
                    clearMarkers(forType: key)
                }
            }
        }
        for key in searchKeywords{
            if !markers.keys.contains(key){
                self.fetchGoogleData(forLocation: currentLocation!, locationName: key, searchRadius: self.searchRadius )
            }
        }
        if self.reacheableSteps.count != 0{
            for step in self.reacheableSteps {
                for keyword in self.searchKeywords{
                    self.fetchGoogleData(forLocation: CLLocation(latitude: step.startLocation!.lat!, longitude: step.startLocation!.lng!), locationName: keyword, searchRadius: 2000)
                }
                
                for keyword in self.searchKeywords{
                    self.fetchGoogleData(forLocation: CLLocation(latitude: step.endLocation!.lat!, longitude: step.endLocation!.lng!), locationName: keyword, searchRadius: 2000)
                }
            }
        }
        dismiss(animated: true)
    }
    
    @objc func filterClicked() {
        self.performSegue(withIdentifier: "GoToFilterController", sender:self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "GoToLocationDetailsViewController") {
            let viewController = segue.destination as! LocationDetailsViewController
            viewController.placeDetail = self.placedetail
            var photoRefs = [String]()
            if let photos = placedetail?.result?.photos {
                for photoRef in photos {
                    photoRefs.append(photoRef.photoreference!)
                }
            }
            viewController.photoReferences = photoRefs
        } else if (segue.identifier == "GoToFilterController") {
            guard let navigationController = segue.destination as? UINavigationController,
                let controller = navigationController.topViewController as? FilterTableViewController else {
                    return
            }
            controller.selectedTypes = searchKeywords
            controller.delegate = self
        }
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
        if self.destination != CLLocation(latitude: marker.position.latitude, longitude: marker.position.longitude) {
            self.googleClient.getDistance(origin: self.currentLocation!, destination: CLLocation(latitude: marker.position.latitude, longitude: marker.position.longitude), completion: { (distanceResult) in
                switch distanceResult {
                case let .success(distance):
                    self.distanceLabel.removeFromSuperview()
                    self.distanceLabel.text = "\(round(distance.rows![0].elements![0].distance!.value! / 1000 * 0.621371)) miles"
                    self.distanceLabel.backgroundColor = UIColor(red:0.00, green:0.53, blue:1.00, alpha:1.0)
                    self.distanceLabel.textColor = UIColor.white
                    self.distanceLabel.alpha = 0.8
                    self.distanceLabel.translatesAutoresizingMaskIntoConstraints = false
                    self.mapView.addSubview(self.distanceLabel)
                    self.distanceLabel.leadingAnchor.constraint(equalTo: self.mapView.leadingAnchor, constant: 10).isActive = true
                    self.distanceLabel.centerYAnchor.constraint(equalTo: self.mapView.centerYAnchor).isActive = true
                case let .failure(error):
                    print(error)
                }
            })
        }

        // setting the position to destination's coordinate
        if !self.firstPathDrawn {
            self.destination = CLLocation(latitude: marker.position.latitude, longitude: marker.position.longitude)
            self.getDirectionBtn = UIButton(type: .system)
            self.getDirectionBtn!.frame = CGRect(x: 150, y: 100, width: 150, height: 30)
            self.getDirectionBtn!.setTitle("Get Direction", for: .normal)
            self.getDirectionBtn!.backgroundColor = UIColor(red:0.00, green:0.53, blue:1.00, alpha:1.0)
            self.getDirectionBtn!.layer.cornerRadius = 5
            self.getDirectionBtn!.setTitleColor(.white, for: .normal)
            self.getDirectionBtn!.addTarget(self, action: #selector(getDirectionBtnTapped), for: .touchUpInside)
        } else {
            self.waypoint = CLLocation(latitude: marker.position.latitude, longitude: marker.position.longitude)
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
        self.removeSubviewsFromStackView(stackView: self.buttonsStackView)
        if !firstPathDrawn {
            self.buttonsStackView.addArrangedSubview(self.getDirectionBtn!)
        } else {
            self.buttonsStackView.addArrangedSubview(self.addWayPointBtn!)
        }
        self.buttonsStackView.addArrangedSubview(self.cancelBtn!)
        self.buttonsStackView!.axis = .vertical
        self.buttonsStackView!.spacing = 30
        // enables auto layout for buttons
        self.buttonsStackView!.translatesAutoresizingMaskIntoConstraints = false
        self.mapView.addSubview(buttonsStackView!)
        
        self.buttonsStackView!.centerXAnchor.constraint(equalTo: self.mapView.centerXAnchor).isActive = true
        self.buttonsStackView!.bottomAnchor.constraint(lessThanOrEqualTo: self.mapView.bottomAnchor, constant: -50).isActive = true
        return false
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        // performs segue only if the icon is a placemarker
        if placedetail != nil {
            if self.isRestaurant {
                self.performSegue(withIdentifier: "GoToLocationDetailsViewController", sender:self)
            }
        }
        self.distanceLabel.removeFromSuperview()
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        self.distanceLabel.removeFromSuperview()
        if firstPathDrawn {
            self.showStartNavBtn()
        }
        if isInNavigation {
            if showingStopNavBtn == false {
                stopNavBtn = UIButton(type: .system)
                stopNavBtn!.frame = CGRect(x: 0, y: 0, width: 100, height: 30)
                stopNavBtn!.setTitle("Exit", for: .normal)
                stopNavBtn!.backgroundColor = UIColor(red:1.00, green:0.30, blue:0.00, alpha:1.0)
                stopNavBtn!.layer.cornerRadius = 5
                stopNavBtn!.setTitleColor(.white, for: .normal)
                stopNavBtn!.addTarget(self, action: #selector(stopNavBtnTapped), for: .touchUpInside)
                
                stopNavBtn!.translatesAutoresizingMaskIntoConstraints = false
                
                self.mapView.addSubview(stopNavBtn!)
                
                stopNavBtn!.bottomAnchor.constraint(equalTo: self.mapView.bottomAnchor).isActive = true
                stopNavBtn!.leadingAnchor.constraint(equalTo: self.navigationTextView.trailingAnchor, constant: 10).isActive = true
                stopNavBtn!.widthAnchor.constraint(equalToConstant: 80).isActive = true
                stopNavBtn!.heightAnchor.constraint(equalToConstant: 40).isActive = true
            } else {
                self.stopNavBtn?.removeFromSuperview()
            }
            showingStopNavBtn = !showingStopNavBtn
        }
        //hiding keyboard on taping map
        searchBar.resignFirstResponder()
    }
    
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        let geocoder = GMSGeocoder()
        geocoder.reverseGeocodeCoordinate(coordinate) { (response, error) in
            if let response = response {
                let marker = GMSMarker(position: coordinate)
                var strVal = ""
                if let lines = response.firstResult()?.lines {
                    for line in lines {
                        strVal += line
                    }
                }
                marker.title = strVal
                marker.map = self.mapView
            } else if let error = error {
                let marker = GMSMarker(position: coordinate)
                marker.map = self.mapView
                print(error)
            }
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
            locationBtn.setImage(UIImage(named: "locationIcon"), for: .normal)
            locationManager.stopUpdatingLocation()
            locationManager.stopUpdatingHeading()
        }
    }
    
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        self.isRestaurant = false
        let view = UIView(frame: CGRect.init(x: 0, y: 0, width: 200, height: 100))
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 6
        
        if let place = marker as? PlaceMarker {
            self.isRestaurant = true
            googleClient.getPlaceDetail(placeId: place.place.placeID){
                (response) in
                switch response{
                case let .success(detail):
                    self.placedetail = detail
                case let .failure(error):
                    print(error)
                }
            }
            
            let lbl1 = UILabel(frame: CGRect.init(x: 8, y: 8, width: view.frame.size.width - 16, height: 15))
            lbl1.text = place.place.name
            lbl1.font = UIFont.systemFont(ofSize: 14, weight: .heavy)
            view.addSubview(lbl1)
            
            let lbl2 = UILabel(frame: CGRect.init(x: lbl1.frame.origin.x , y: lbl1.frame.origin.y+lbl1.frame.size.height + 3, width: view.frame.size.width - 16, height: 15))
            lbl2.text = place.place.address
            lbl2.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            view.addSubview(lbl2)
            
            let lbl3 = UILabel(frame: CGRect.init(x: lbl2.frame.origin.x , y: lbl2.frame.origin.y+lbl2.frame.size.height + 3, width: view.frame.size.width - 16, height: 15))
            lbl3.text = (place.place.openingHours?.isOpen! == true) ? "Open":"Closed"
            lbl3.font = UIFont.systemFont(ofSize: 12, weight: .thin)
            lbl3.textColor = (place.place.openingHours?.isOpen! == true) ? UIColor.red:UIColor.green
            view.addSubview(lbl3)
            
            let placedetails = UIButton(type: .system)
            placedetails.frame = CGRect(x: lbl3.frame.origin.x, y: lbl3.frame.origin.y+lbl3.frame.size.height + 5 , width: view.frame.size.width - 16, height: 30)
            placedetails.setTitle("Details", for: .normal)
            placedetails.backgroundColor = UIColor(red:0.00, green:0.53, blue:1.00, alpha:1.0)
            placedetails.layer.cornerRadius = 5
            placedetails.setTitleColor(.white, for: .normal)
            placedetails.addTarget(self, action: #selector(self.placeDetailsNav), for: .touchUpInside)
            view.addSubview(placedetails)
            
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
        self.buttonsStackView!.removeFromSuperview()
        // remove buttons from the view
        self.removeSubviewsFromStackView(stackView: self.buttonsStackView)
        self.buttonsStackView!.removeFromSuperview()
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
        self.buttonsStackView.addArrangedSubview(self.startNavBtn!)
        self.buttonsStackView.addArrangedSubview(self.cancelBtn!)
        self.buttonsStackView!.axis = .vertical
        self.buttonsStackView!.spacing = 30
        // enables auto layout for buttons
        self.buttonsStackView!.translatesAutoresizingMaskIntoConstraints = false
        self.mapView.addSubview(buttonsStackView!)
        
        self.buttonsStackView!.centerXAnchor.constraint(equalTo: self.mapView.centerXAnchor).isActive = true
        self.buttonsStackView!.bottomAnchor.constraint(lessThanOrEqualTo: self.mapView.bottomAnchor, constant: -50).isActive = true
    }
    
    @objc func getDirectionBtnTapped(_ sender: UIButton) {
        self.firstPathDrawn = true
        self.distanceLabel.removeFromSuperview()
        let destination2D = CLLocationCoordinate2D(latitude: self.destination!.coordinate.latitude, longitude: self.destination!.coordinate.longitude)
        let currentLocation2D = CLLocationCoordinate2D(latitude: self.currentLocation!.coordinate.latitude, longitude: self.currentLocation!.coordinate.longitude)
        let bounds = GMSCoordinateBounds(coordinate: currentLocation2D, coordinate: destination2D)
        var insets = UIEdgeInsets()
        insets.bottom = 50
        insets.top = 50
        insets.right = 50
        insets.left = 50
        let camera = self.mapView.camera(for: bounds, insets: insets)!
        self.mapView.animate(to: camera)
        self.drawPath(origin: currentLocation!, destination: self.destination!)
        showStartNavBtn()
    }
    
    @objc func addWaypointBtntapped(_ sender: UIButton) {
        let destination = self.destination
        self.waypoints.append(waypoint!)
        let destination2D = CLLocationCoordinate2D(latitude: self.destination!.coordinate.latitude, longitude: self.destination!.coordinate.longitude)
        let currentLocation2D = CLLocationCoordinate2D(latitude: self.currentLocation!.coordinate.latitude, longitude: self.currentLocation!.coordinate.longitude)
        let bounds = GMSCoordinateBounds(coordinate: currentLocation2D, coordinate: destination2D)
        var insets = UIEdgeInsets()
        insets.bottom = 50
        insets.top = 50
        insets.right = 50
        insets.left = 50
        let camera = self.mapView.camera(for: bounds, insets: insets)!
        self.mapView.animate(to: camera)
        self.drawPath(origin: currentLocation!, destination: destination!, waypoints: waypoints)
        showStartNavBtn()
    }
    
    @objc func startNavBtnTapped(_ sender: UIButton) {
        UIApplication.shared.isIdleTimerDisabled = true
        locationBtnHasBeenTapped = false
        locationBtn.setImage(UIImage(named: "compus"), for: .normal)
        self.removeSubviewsFromStackView(stackView: self.buttonsStackView)
        self.removeSubviewsFromStackView(stackView: self.travelInfoStackView)
        self.speedLabel.text = "\(round(abs(self.locationManager.location!.speed * 3600.0 * 0.000621371)).description)/mph"
        self.speedLabel.textAlignment = .center
        self.speedLabel.backgroundColor = UIColor.black
        self.speedLabel.alpha = 0.8
        self.speedLabel.layer.masksToBounds = true
        self.speedLabel.textColor = UIColor.white
        
        self.zoom = 18
        self.viewingAngle = 45
        self.isInNavigation = true
        self.usingCompus = true
        self.currentStep = self.navigationDirection!.routes![0].legs![0].steps![0]
        
        self.fuelRemainingTextView.text = "\(self.myCar!.getFuelRemaining())/\(self.myCar!.fuelCapacity) gals"
        self.fuelRemainingTextView.font = UIFont(name: self.fuelRemainingTextView.font!.fontName, size: 15)
        self.fuelRemainingTextView.backgroundColor = self.myCar!.getColorForFuelRemaining()
        self.fuelRemainingTextView.textColor = UIColor.white
        self.fuelRemainingTextView.alpha = 0.8
        self.fuelRemainingTextView.layer.masksToBounds = true
        
        self.navigationTextView.text = self.currentStep?.htmlInstructions!.html2String
        self.navigationTextView.backgroundColor = UIColor(red:0.00, green:0.53, blue:1.00, alpha:1.0)
        self.navigationTextView.textColor = UIColor.white
        self.navigationTextView.alpha = 0.8
        self.navigationTextView.layer.masksToBounds = true
        self.navigationTextView.font = UIFont(name: self.navigationTextView.font!.fontName, size: 18)
        
        self.mapView.addSubview(self.speedLabel)
        self.mapView.addSubview(self.fuelRemainingTextView)
        self.mapView.addSubview(self.navigationTextView)
        
        // constraints for navigationTextView
        self.navigationTextView.translatesAutoresizingMaskIntoConstraints = false
        self.navigationTextView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        self.navigationTextView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        self.navigationTextView.leadingAnchor.constraint(equalTo: self.mapView.leadingAnchor).isActive = true
        self.navigationTextView.bottomAnchor.constraint(equalTo: self.mapView.bottomAnchor, constant: -10).isActive = true
        // constraints for fuelRemainingTextView
        self.fuelRemainingTextView.translatesAutoresizingMaskIntoConstraints = false
        self.fuelRemainingTextView.widthAnchor.constraint(equalToConstant: 130).isActive = true
        self.fuelRemainingTextView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        self.fuelRemainingTextView.leadingAnchor.constraint(equalTo: self.mapView.leadingAnchor).isActive = true
        self.fuelRemainingTextView.bottomAnchor.constraint(equalTo: self.speedLabel.topAnchor, constant: -10).isActive = true
        // constraints for speedLabel
        self.speedLabel.translatesAutoresizingMaskIntoConstraints = false
        self.speedLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        self.speedLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
        self.speedLabel.leadingAnchor.constraint(equalTo: self.mapView.leadingAnchor).isActive = true
        self.speedLabel.bottomAnchor.constraint(equalTo: self.navigationTextView.topAnchor, constant: -10).isActive = true
        
        currentStepIndex = 0
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        updateCamera = true
        let camera = GMSCameraPosition.camera(withLatitude: currentLocation!.coordinate.latitude, longitude: currentLocation!.coordinate.longitude, zoom: self.zoom!, bearing: 0, viewingAngle: self.viewingAngle!)
        self.mapView.animate(to: camera)
    }
    
    @objc func stopNavBtnTapped(_ sender: UIButton) {
        self.firstPathDrawn = false
        self.waypoints.removeAll()
        UIApplication.shared.isIdleTimerDisabled = false
        self.removeLabelsForNav()
        self.stopNavBtn!.removeFromSuperview()
        self.isInNavigation = false
        self.mapView.clear()
        self.zoom = 15
        let camera = GMSCameraPosition.camera(withLatitude: self.currentLocation!.coordinate.latitude, longitude: self.currentLocation!.coordinate.longitude, zoom: zoom!)
        self.mapView.animate(to: camera)
    }
    
    @objc func cancelBtnTapped(_ sender: UIButton) {
        self.waypoints.removeAll()
        self.distanceLabel.removeFromSuperview()
        self.firstPathDrawn = false
        locationManager.startUpdatingLocation()
        self.removeSubviewsFromStackView(stackView: self.buttonsStackView)
        self.removeSubviewsFromStackView(stackView: self.travelInfoStackView)
        self.mapView.clear()
        let camera = GMSCameraPosition.camera(withLatitude: self.currentLocation!.coordinate.latitude, longitude: self.currentLocation!.coordinate.longitude, zoom: zoom!)
        self.mapView.animate(to: camera)
        self.buttonsStackView!.removeFromSuperview()
        reacheableSteps.removeAll()
        for keyword in searchKeywords{
            self.fetchGoogleData(forLocation: currentLocation!, locationName: keyword, searchRadius: self.searchRadius )
        }
    }
    
    @objc func locationBtnTapped(_ sender: UIButton) {
        self.zoom = 16
        if isInNavigation {
            self.viewingAngle = 45
        }
        let camera = GMSCameraPosition.camera(withLatitude: self.currentLocation!.coordinate.latitude, longitude: self.currentLocation!.coordinate.longitude, zoom: self.zoom!, bearing: 0, viewingAngle: self.viewingAngle!)
        mapView.animate(to: camera)
        self.locationManager.startUpdatingLocation()
        if locationBtnHasBeenTapped {
            self.locationManager.startUpdatingHeading()
            locationBtn.setImage(UIImage(named: "compus"), for: .normal)
        } else {
            self.locationManager.stopUpdatingHeading()
            locationBtn.setImage(UIImage(named: "locationIcon"), for: .normal)
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
        let distanceToFinalDestInMeters = currentLocation.distance(from: destination!)
        if distanceInMeters < 20 || distanceToFinalDestInMeters < 20 {
            return true
        } else {
            return false
        }
    }
    
    private func switchStep() -> Bool {
        self.currentStepIndex! += 1
        // checks if there are any more steps to take. If there are, it switches to the next step and return true. If not, it will return false - end of the destination.
        if let nextStep = self.navigationDirection!.routes![0].legs![0].steps?[self.currentStepIndex!] {
            self.currentStep = nextStep
            self.navigationTextView.text! = self.currentStep!.htmlInstructions!.html2String
            return true
        } else {
            return false
        }
    }
    
    private func showEndOfNavigationLabel() {
        self.navigationTextView.text! = "You have arrived"
    }
    
    @objc func placeDetailsNav(_ sender: UIButton) {
        self.performSegue(withIdentifier: "GoToLocationDetailsViewController", sender:self)
    }
    
    // Removes subviews in a particular stack view
    private func removeSubviewsFromStackView(stackView: UIStackView) {
        for view in stackView.subviews {
            view.removeFromSuperview()
        }
    }
    
    private func removeLabelsForNav() {
        self.navigationTextView.removeFromSuperview()
        self.speedLabel.removeFromSuperview()
        self.fuelRemainingTextView.removeFromSuperview()
    }
    
    private func showTravelInfo(leg: Direction.Route.Leg) {
        self.removeSubviewsFromStackView(stackView: self.travelInfoStackView)
        let distanceLabel = UILabel()
        distanceLabel.text = leg.distance!.text!.description
        distanceLabel.alpha = 0.8
        distanceLabel.backgroundColor = UIColor(red:0.00, green:0.53, blue:1.00, alpha:1.0)
        distanceLabel.textColor = UIColor.white
        distanceLabel.layer.masksToBounds = true
        
        let durationLabel = UILabel()
        durationLabel.text = leg.duration!.text!.description
        durationLabel.alpha = 0.8
        durationLabel.backgroundColor = UIColor(red:0.00, green:0.53, blue:1.00, alpha:1.0)
        durationLabel.textColor = UIColor.white
        durationLabel.layer.masksToBounds = true
        
        self.travelInfoStackView.addArrangedSubview(distanceLabel)
        self.travelInfoStackView.addArrangedSubview(durationLabel)
        self.travelInfoStackView.axis = .vertical
        self.travelInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        self.travelInfoStackView.backgroundColor = UIColor(red: 0, green: 0.698, blue: 1, alpha: 1.0)
        self.travelInfoStackView.spacing = 0
        self.travelInfoStackView.layer.cornerRadius = 5
        
        self.mapView.addSubview(self.travelInfoStackView)
        self.travelInfoStackView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        self.travelInfoStackView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        self.travelInfoStackView.leadingAnchor.constraint(equalTo: self.mapView.leadingAnchor, constant: 0).isActive = true
        self.travelInfoStackView.bottomAnchor.constraint(equalTo: self.mapView.bottomAnchor, constant: 0).isActive = true
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
extension UIImage {
    class func imageForGasStation(price: Double, color: UIColor) -> UIImage {
        let DynamicView=UIView(frame: CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 50, height: 50)))
        DynamicView.backgroundColor=UIColor.clear
        var imageViewForPinMarker : UIImageView
        imageViewForPinMarker  = UIImageView(frame:CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 50, height: 50)))
        imageViewForPinMarker.image = UIImage(named:"prices")?.withRenderingMode(.alwaysTemplate)
        imageViewForPinMarker.tintColor = color
        let text = UILabel(frame:CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 40, height: 30)))
        text.text = String("\(price)")
        text.textColor = UIColor.white
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
        return imageConverted
    }
}

struct FilterKeywordWithImage{
    let key: String
    let name: String
    let icon: UIImage?
}


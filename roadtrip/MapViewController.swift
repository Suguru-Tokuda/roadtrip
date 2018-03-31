import UIKit
import GoogleMaps
import GooglePlaces

class MapViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    //https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=-33.870943,151.190311&radius=1000&rankby=prominence&sensor=true&key=AIzaSyD14jarz6jPaHCozkfKHcNLVthhuJhtwqg
    var locationManager = CLLocationManager()
    var destination: GMSPlace?
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var addresslbl: UILabel!
    
    lazy var googleClient = GoogleClient()
    var currentLocation: CLLocation = CLLocation(latitude: 42.361145, longitude: -71.057083)
    var searchKeywords:[String] = []
    var locationPetrol : String = "petrol"
    var locationGasStation : String = "gas_station"
    var locationFood : String = "food"
    var searchRadius : Int = 500
    let searchBar = UISearchBar()
    var markers=[String:[PlaceMarker]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //adding all to search
        searchKeywords.append(locationGasStation)
        searchKeywords.append(locationPetrol)
        searchKeywords.append(locationFood)
        
        locationManager.delegate = self
        mapView.delegate = self
        //self.navigationController?.isNavigationBarHidden = true
        locationManager.requestWhenInUseAuthorization()
        // let jsonURLString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=-33.870943,151.190311&radius=1000&rankby=prominence&sensor=true&key=AIzaSyD14jarz6jPaHCozkfKHcNLVthhuJhtwqg"
        // fetchGoogleData(forLocation: currentLocation, locationName: locationName, searchRadius: searchRadius )
        
        // expandable search bar
        // https://stackoverflow.com/questions/38580175/swift-expandable-search-bar-in-header
        // expandableview to end of code
        addingExpandableSearch()
        // setting spanner for getting to settings
        let settingsBtn: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "spanner")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(settingsTapped(_:)))
        self.navigationItem.leftBarButtonItem = settingsBtn
        
        // setting the navigation bar to transparent
        self.navigationController?.presentTransparentNavigationBar()
        
        // drawing lines
        let origin:CLLocation = CLLocation(latitude: 40.6936, longitude: -89.5890)
        let dest:CLLocation = CLLocation(latitude: 39.781721 , longitude: -89.650148)
        drawPath(origin: origin, destination: dest)
    }
    
    func fetchAllFor(getMarkerType markerType:String)->[PlaceMarker]{
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
    
    //part of exapandable search
    var leftConstraint: NSLayoutConstraint!
    var navigationDirection: Direction?
    
    @objc func settingsTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showCarSummary", sender: self)
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        //hiding keyboard on taping map
        searchBar.resignFirstResponder()
    }
    
    func addingExpandableSearch(){
        // Expandable area.
        let expandableView = ExpandableView()
        navigationItem.titleView = expandableView
        
        // Search button.
        // navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(toggle))
        let imgforsearch = UIImage(named: "search")!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        let imgforfilter = UIImage(named: "filter")!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        let searchButton = UIBarButtonItem(image: imgforsearch, style: .plain, target: self, action: #selector(toggle))
        let forfilter = UIBarButtonItem(image: imgforfilter, style: .plain, target: self, action: #selector(filterClicked))
        navigationItem.setRightBarButtonItems([searchButton,forfilter], animated: true)
        // Search bar.
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        expandableView.addSubview(searchBar)
        leftConstraint = searchBar.leftAnchor.constraint(equalTo: expandableView.leftAnchor)
        leftConstraint.isActive = false
        searchBar.rightAnchor.constraint(equalTo: expandableView.rightAnchor).isActive = true
        searchBar.topAnchor.constraint(equalTo: expandableView.topAnchor).isActive = true
        searchBar.bottomAnchor.constraint(equalTo: expandableView.bottomAnchor).isActive = true
        
    }
    
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
        guard let location = locations.first else {
            return
        }
        
        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 15, bearing: 0, viewingAngle: 0)
        //DispatchQueue.main.async {
        //locationManager.stopUpdatingLocation()
        clearAllMarkers()
        for keyword in searchKeywords{
            self.fetchGoogleData(forLocation: location, locationName: keyword, searchRadius: self.searchRadius )
        }
        currentLocation = location
    }
    private func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D) {
        let geocoder = GMSGeocoder()
        
        geocoder.reverseGeocodeCoordinate(coordinate) { response, error in
            guard let address = response?.firstResult(), let lines = address.lines else {
                return
            }
            
            self.addresslbl.text = lines.joined(separator: "\n")
            
            let labelHeight = self.addresslbl.intrinsicContentSize.height
            self.mapView.padding = UIEdgeInsets(top: self.view.safeAreaInsets.top, left: 0, bottom: labelHeight, right: 0)
            
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        reverseGeocodeCoordinate(position.target)
    }
    
}

extension MapViewController {
    func fetchGoogleData(forLocation: CLLocation, locationName: String, searchRadius: Int) {
        //        let possibleTypes = ["bar", "gas_station", "restaurant"]
        let group1 = DispatchGroup()
        group1.enter()
        googleClient.getGooglePlacesData(forKeyword: locationName, location: forLocation, withinMeters: searchRadius) { (response) in
            DispatchQueue.main.sync{
                let places = response.results
                for place in places {
                    
                    let marker = PlaceMarker(place: place)
                    marker.title = place.name
                    marker.snippet = "The place is \(place.openingHours?.isOpen == true ? "open" : "closed")"
                    switch true{
                    case place.types.contains("gas_station"),place.types.contains("petrol"):
                        marker.icon = UIImage(named: "Gas_station")
                        marker.map = self.mapView
                    case place.types.contains("food"),place.types.contains("restaurant"),place.types.contains("bar"):
                        marker.icon = UIImage(named: "Food")
                        marker.map = self.mapView
                    default:
                        break
                    }
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
                        switch true{
                        case place.types.contains("gas_station"):
                            marker.icon = UIImage(named: "Gas_station")
                            marker.map = self.mapView
                        case place.types.contains("food"),place.types.contains("restaurant"),place.types.contains("bar"):
                            marker.icon = UIImage(named: "Food")
                            marker.map = self.mapView
                        default:
                            break
                        }
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
                        switch true{
                        case place.types.contains("gas_station"):
                            marker.icon = UIImage(named: "Gas_station")
                            marker.map = self.mapView
                        case place.types.contains("food"),place.types.contains("restaurant"),place.types.contains("bar"):
                            marker.icon = UIImage(named: "Food")
                            marker.map = self.mapView
                        default:
                            break
                        }
                        self.addMarker(markerType: locationName, marker: marker)
                    }
                }
                
            }
        })
        
    }
    
    func drawPath(origin: CLLocation, destination: CLLocation) {
        googleClient.getDestinationPathByCoordinates(origin: origin, destination: destination) { (directionsResult) in
            switch directionsResult {
            case let .success(direction):
                self.navigationDirection = direction
                let overViewPolyine = direction.routes![0].overviewPolyline
                let route = overViewPolyine!.points
                let path: GMSPath = GMSPath(fromEncodedPath: route!)!
                let polyline = GMSPolyline(path: path)
                polyline.strokeWidth = 4
                polyline.strokeColor = .red
                polyline.geodesic = true
                polyline.map = self.mapView
            // show gas stations & restaurants on the steps
            case let .failure(error):
                print(error)
            }
        }
    }
}

extension MapViewController{
    //    part of expandable search bar
    @objc func toggle() {
        
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
        let isOpen = leftConstraint.isActive == true
        
        // Inactivating the left constraint closes the expandable header.
        leftConstraint.isActive = isOpen ? false : true
        
        // Animate change to visible.
        UIView.animate(withDuration: 1, animations: {
            self.navigationItem.titleView?.alpha = isOpen ? 0 : 1
            self.navigationItem.titleView?.layoutIfNeeded()
        })
    }
    
}

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
                self.fetchGoogleData(forLocation: currentLocation, locationName: key, searchRadius: self.searchRadius )
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

extension MapViewController: GMSAutocompleteViewControllerDelegate {
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        self.destination = place
        let lat = self.destination!.coordinate.latitude
        let long = self.destination!.coordinate.longitude
        
        let camera = GMSCameraPosition.camera(withLatitude: lat, longitude: long, zoom: 6.0)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        view = mapView
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: lat, longitude: long)
        marker.title = place.name
        marker.snippet = place.formattedAddress
        marker.map = mapView
        
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true

        print("Place name: \(place.name)")
        print("Place address: \(String(describing: place.formattedAddress))")
        print("Place attributions: \(String(describing: place.attributions))")
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print("Error: ", error.localizedDescription)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
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


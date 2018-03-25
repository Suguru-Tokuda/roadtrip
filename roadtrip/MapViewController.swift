import UIKit
import GoogleMaps
import GooglePlaces

class MapViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    //https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=-33.870943,151.190311&radius=1000&rankby=prominence&sensor=true&key=AIzaSyD14jarz6jPaHCozkfKHcNLVthhuJhtwqg
    var locationManager = CLLocationManager()
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var addresslbl: UILabel!
    
    lazy var googleClient = GoogleClient()
    var currentLocation: CLLocation = CLLocation(latitude: 42.361145, longitude: -71.057083)
    var searchKeywords:[String] = []
    var locationPetrol : String = "petrol"
    var locationGasStation : String = "gas_station"
    var locationFood : String = "food"
    var searchRadius : Int = 1000
    let searchBar = UISearchBar()
    //part of exapandable search
    var leftConstraint: NSLayoutConstraint!
    
    
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
        //        let jsonURLString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=-33.870943,151.190311&radius=1000&rankby=prominence&sensor=true&key=AIzaSyD14jarz6jPaHCozkfKHcNLVthhuJhtwqg"
        //        fetchGoogleData(forLocation: currentLocation, locationName: locationName, searchRadius: searchRadius )
        
        //        expandable search bar
        //        https://stackoverflow.com/questions/38580175/swift-expandable-search-bar-in-header
        //        expandableview to end of code
        addingExpandableSearch()
        //        setting spanner for getting to settings
        var backBtn = UIImage(named: "spanner")
        backBtn = backBtn?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        
        self.navigationController!.navigationBar.backIndicatorImage = backBtn;
        self.navigationController!.navigationBar.backIndicatorTransitionMaskImage = backBtn;
        self.navigationController!.navigationBar.tintColor = UIColor.blue
        
        //        setting the navigation bar to transparent
        self.navigationController?.presentTransparentNavigationBar()
        
        // drawing lines
        let origin:CLLocation = CLLocation(latitude: 40.6936, longitude: -89.5890)
        let dest:CLLocation = CLLocation(latitude: 39.781721 , longitude: -89.650148)
        drawPath(origin: origin, destination: dest)
        
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
        //        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(toggle))
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
        mapView.clear()
        
        if searchKeywords.contains(locationGasStation) {
            self.fetchGoogleData(forLocation: location, locationName: self.locationGasStation, searchRadius: self.searchRadius )
        }
        self.fetchGoogleData(forLocation: location, locationName: self.locationPetrol, searchRadius: self.searchRadius )
        self.fetchGoogleData(forLocation: location, locationName: self.locationFood, searchRadius: self.searchRadius )
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
                        
                    }
                }
                
            }
        })
        
    }
    
    func drawPath(origin: CLLocation, destination: CLLocation) {
        googleClient.getDestinationPathByCoordinates(origin: origin, destination: destination) { (directionsResult) in
            switch directionsResult {
            case let .success(direction):
                let overviewPolyline = direction.routes![0].overviewPolyline
                let points = overviewPolyline!.points
                let path = GMSPath.init(fromEncodedPath: points!)
                let polyline = GMSPolyline.init(path: path)
                polyline.strokeWidth = 4
                polyline.strokeColor = .red
                polyline.map = self.mapView
            case let .failure(error):
                print(error)
            }
        }
    }
    
}

extension MapViewController{
    //    part of expandable search bar
    @objc func toggle() {
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


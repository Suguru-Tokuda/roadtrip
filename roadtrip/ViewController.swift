import UIKit
import GoogleMaps

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var googleMapsAPIKey: String!
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var lat: Double?
    var long: Double?

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        googleMapsAPIKey = appDelegate.googleMapsAPIKey
        GMSServices.provideAPIKey(googleMapsAPIKey)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            self.lat = location.coordinate.latitude
            self.long = location.coordinate.longitude
            print(location.coordinate)
            let camera = GMSCameraPosition.camera(withLatitude: lat!, longitude: long!, zoom: 6.0)
            let mapView = GMSMapView.map(withFrame: .zero, camera: camera)
            mapView.isMyLocationEnabled = true
            self.view = mapView
            
//            let marker = GMSMarker()
//            marker.position = CLLocationCoordinate2D(latitude: lat!, longitude: long!)
//            marker.title = "ISU"
//            marker.snippet = "ISU Snippet"
//            marker.map = mapView
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}


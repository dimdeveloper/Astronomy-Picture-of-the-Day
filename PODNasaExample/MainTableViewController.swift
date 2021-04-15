//
//  MainTableViewController.swift
//  PODNasaExample
//
//  Created by TheMacUser on 20.03.2021.
import youtube_ios_player_helper
import UIKit

class MainTableViewController: UITableViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, YTPlayerViewDelegate {
    
    
    @IBOutlet var playerView: YTPlayerView!
    @IBOutlet weak var chevronLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var imagesCollectionView: UICollectionView!
    @IBOutlet weak var imageName: UILabel!
    @IBOutlet weak var imageDescription: UITextView!
    
    @IBAction func datePickerDateChanged(_ sender: UIDatePicker) {
        currentDate = datePicker.date
        initialSetupCollectionView()
    }
    var tapGesture = UITapGestureRecognizer()
    var chevronRotationAngle: CGFloat = 0
    var isDatePickerHidden: Bool = true {
        didSet {
            chevronRotationAngle = isDatePickerHidden ? CGFloat.pi/2 : -CGFloat.pi/2
            UIView.animate(withDuration: 0.3) {
                self.chevronLabel.transform = CGAffineTransform(rotationAngle: self.chevronRotationAngle)
                
            }
        }
    }
    var dateArray: [Date] = [] {
        didSet {
            dateArray.sort { (date1, date2) -> Bool in
                return date1 < date2
            }
        }
    }
    let imagesCollectionViewLayout = SnappingFlowLayout()
    let today = Date()
    var imagesDictionary: [Date : UIImage?] = [:] {
        didSet {
            DispatchQueue.main.async {
                self.imagesCollectionView.reloadData()
            }
            
        }
    }
    var podObjectDictionary: [Date : PODObject] = [:]
    let request = Requests()
    lazy var currentDate = today {
        didSet {
            datePicker.date = currentDate
            if let object = podObjectDictionary[currentDate] {
                updateTableView(with: object)
            } else {
                fetchObject(withDate: currentDate)
            }
        }
    }
    var indexPathForVisibleCell: IndexPath? {
        let centerX = imagesCollectionView.bounds.midX
        let centerY = imagesCollectionView.bounds.midY
        let centerCollectionView = CGPoint(x: centerX, y: centerY)
        return imagesCollectionView.indexPathForItem(at: centerCollectionView)
    }
    let indexPathOfDateLabel: IndexPath = IndexPath(row: 0, section: 0)
    let indexPathOfDatePicker: IndexPath = IndexPath(row: 1, section: 0)
    let indexPathOfImage: IndexPath = IndexPath(row: 2, section: 0)
    let indexPathOfDescription: IndexPath = IndexPath(row: 4, section: 0)
    var yesterday: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
    }
    var tomorrow: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
    }
    let playVarsDic = ["controls" : 1, "playsinline" : 1, "autohide" : 1, "showinfo" : 1, "autoplay" : 1, "modestbranding" : 1 ]
    var videoPlayerView: YTPlayerView = YTPlayerView()
    var currentObject: PODObject!
    override func viewDidLoad() {
        super.viewDidLoad()
        videoPlayerView.tag = 100
        videoPlayerView.delegate = self
        chevronLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2)
        datePicker.date = today
        datePicker.maximumDate = today
        initialSetupCollectionView()
        fetchObject(withDate: today)
        
   
        
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath {
        case indexPathOfDatePicker:
            if isDatePickerHidden {
                return 0
            } else {
                return datePicker.frame.height
            }
        case indexPathOfImage:
            return 300
        case indexPathOfDescription:
            return 300
        default:
            return 44
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath {
        case indexPathOfDateLabel:
            isDatePickerHidden = !isDatePickerHidden
            tableView.beginUpdates()
            tableView.endUpdates()
        default:
            return
        }
        if isDatePickerHidden == false {
            tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapFunction))
            view.addGestureRecognizer(tapGesture)
        }
    }
    // collectionView setup
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dateArray.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCollectionViewCell
        let date = dateArray[indexPath.row]
        let dayObject = podObjectDictionary[date]
        for singleView in cell.subviews {
                    if singleView == videoPlayerView {
                        singleView.removeFromSuperview()
                    }

                }
        print("Cell subviews count is \(cell.subviews.count)")
        if imagesDictionary[date] == nil {
            cell.imageView.image = UIImage(named: "imagePlaceholder")
            if dayObject?.mediaType == "video" {
                cell.imageView.image = nil
                print("MediaType is Video in Cell")
                videoPlayerView = YTPlayerView(frame: CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height))
                if let videoID = dayObject!.imageURL.getVideoID() {
                    cell.addSubview(videoPlayerView)
                    videoPlayerView.load(withVideoId: videoID, playerVars: playVarsDic)
                    videoPlayerView.playVideo()
                }
            } else {
                
            }
        } else {
            cell.imageView.image = imagesDictionary[date] as? UIImage
        }
        
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sizeOfTheCell = CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        return sizeOfTheCell
    }
    func fetchObject(withDate date: Date){
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        request.fetchNASAPOD(date: date) { object in
            if let object = object {
                DispatchQueue.main.async {
                    self.updateTableView(with: object)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                
                
                self.podObjectDictionary[date] = object
                if object.mediaType == "video" {
                    print("MediaType is Video!")
                    DispatchQueue.main.async {
                        self.imagesCollectionView.reloadData()
                    }
                } else {
                    self.imagesDictionary[date] = self.updateImage(imageStringURL: object.imageURL)
                }
            }
        }
    }
    
    func initialSetupCollectionView(){
        dateArray.removeAll()
        var date: Date!
        if currentDate == today {
            date = today
            for _ in 0...4 {
                dateArray.insert(date, at: 0)
                date = date.yesterday()
            }
        } else {
            date = currentDate
            for _ in 0...4 {
                dateArray.insert(date, at: 0)
                date = date.yesterday()
            }
            date = currentDate.tomorrow()
            for _ in 0...4 {
                if date < today {
                    dateArray.insert(date, at: 0)
                    date = date.tomorrow()
                }
            }
        }
        imagesCollectionView.reloadData()
        setContentOffset()


        
    }
    func setContentOffset(){
        let itemsCount = CGFloat((imagesCollectionView?.numberOfItems(inSection: 0))!)
        imagesCollectionView.setContentOffset(CGPoint(x: imagesCollectionView.collectionViewLayout.collectionViewContentSize.width/itemsCount*4, y: 0), animated: false)
    }
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let indexPathOfVisibleCell = indexPathForVisibleCell else {return}
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        currentDate = dateArray[indexPathOfVisibleCell.row]
        
        if indexPathOfVisibleCell.row == 0 {
            dateArray.insert(yesterday, at: 0)
            imagesCollectionView.reloadData()
            let itemSize = CGSize(width: scrollView.bounds.width, height: scrollView.bounds.height)
            let newOffset: CGPoint = CGPoint(x: itemSize.width, y: 0)
            self.imagesCollectionView.setContentOffset(newOffset, animated: false)
            if dateArray.count > 10 {
                dateArray.removeLast()
                imagesCollectionView.reloadData()
            }
        }
        if indexPathOfVisibleCell.row == 9 && currentDate < today {
            dateArray.append(tomorrow)
            dateArray.removeFirst()
            imagesCollectionView.reloadData()
            let itemSize = CGSize(width: scrollView.bounds.width, height: scrollView.bounds.height)
            let newOffset: CGPoint = CGPoint(x: itemSize.width * 8, y: 0)
            self.imagesCollectionView.setContentOffset(newOffset, animated: false)
            
        }
        
    }
    override func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        if !isDatePickerHidden {
        isDatePickerHidden = !isDatePickerHidden
        tableView.beginUpdates()
        tableView.endUpdates()
        }
    }

    func updateTableView(with object: PODObject){
        imageName.text = object.title
        imageDescription.text = object.description
        dateLabel.text = datePicker.date.convertToString()
    }
    func updateImage(imageStringURL: String) -> UIImage? {
        guard let imageURL = URL(string: imageStringURL), let imageData = try? Data(contentsOf: imageURL) else {
            print("Error retreiving image!")
            return nil}
           return UIImage(data: imageData)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let offset = imagesCollectionView.contentOffset
        let width = imagesCollectionView.bounds.size.width
        
        let index = round(offset.x/width)
        let newOffset: CGPoint = CGPoint(x: index*size.width, y: offset.y)
        coordinator.animate { (context) in
            self.imagesCollectionView.reloadData()
            self.imagesCollectionView.setContentOffset(newOffset, animated: false)
        }

    }
    @objc func tapFunction(){
        isDatePickerHidden = true
        view.removeGestureRecognizer(tapGesture)
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        videoPlayerView.playVideo()
    }

}

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
    var hdImagesDictionary: [Date : UIImage] = [:] {
        didSet{
            if !isHDImageViewHiden {
                hdImage.image = hdImagesDictionary[currentDate]
                print("HDImage is \(hdImage.image)")
            }
        }
    }
    var imagesDictionary: [Date : UIImage] = [:] {
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
    lazy var currentObject: PODObject = podObjectDictionary[currentDate]!
    var hdImageView = UIView()
    var isHDImageViewHiden: Bool = true {
        didSet {
            print("isHDImageViewHiden IS CHANGED \(isHDImageViewHiden)")
            if isHDImageViewHiden {
                print("HDImageView is Hiden")
                hdImageView.isHidden = true
            } else {
                print("HDImageView is NOT Hiden")
                
                if let bigImageSize = hdImagesDictionary[currentDate] {
                    hdImage.image = bigImageSize
                } else {
                    updateHDImage(date: currentDate)
                    hdImage.image = imagesDictionary[currentDate]
                }
                hdImageView.isHidden = false
                
//                guard let object = podObjectDictionary[currentDate], let image = imagesDictionary[currentDate] else {return}
//                if let bigImage = hdImagesDictionary[currentDate] {
//                        self.hdImage.image = bigImage
//                        print("hdImage.image = bigImage")
//
//                } else {
//                    DispatchQueue.main.async {
//                        self.hdImage.image = image
//                        print("hdImage.image = Image")
//                    }
//
//                    if let bigResolutionImage = updateImage(imageStringURL: object.hdImageURL!) {
//                        hdImagesDictionary[currentDate] = bigResolutionImage
//                        print("HD Image is \(bigResolutionImage)")
//                    }
//                }
                
            }
        }
    }
    var hdImage = UIImageView()
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.alwaysBounceVertical = false
        //hdImageView = UIView()
       //hdImageView = UIView(frame: UIScreen.main.bounds)
        hdImageView.layer.backgroundColor = (UIColor.black.cgColor)
        hdImageView.alpha = 1
        view.addSubview(hdImageView)
        hdImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hdImageView.widthAnchor.constraint(equalTo: view.widthAnchor),
            hdImageView.heightAnchor.constraint(equalToConstant: 500),
            hdImageView.heightAnchor.constraint(equalTo: view.heightAnchor),
            hdImageView.topAnchor.constraint(equalTo: view.topAnchor),
            hdImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
            
        ])
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
        button.setTitle("Close", for: .normal)
        button.addTarget(self, action: #selector(closehdImageView), for: .touchUpInside)
        hdImage = UIImageView(frame: CGRect(x: 0, y: 0, width: self.hdImageView.frame.width, height: hdImageView.frame.height))
        hdImage.contentMode = .scaleAspectFit
        hdImageView.addSubview(hdImage)
        hdImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hdImage.widthAnchor.constraint(equalTo: hdImageView.widthAnchor),
            hdImage.heightAnchor.constraint(equalTo: hdImageView.heightAnchor),
            hdImage.centerXAnchor.constraint(equalTo: hdImageView.centerXAnchor),
            hdImage.centerYAnchor.constraint(equalTo: hdImageView.centerYAnchor)
        ])
        
        hdImageView.addSubview(button)
        hdImageView.isHidden = true
        videoPlayerView = YTPlayerView(frame: CGRect(x: 0, y: 0, width: 350, height: 250))
        videoPlayerView.load(withVideoId: "")
        videoPlayerView.delegate = self
        chevronLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2)
        datePicker.date = today
        datePicker.maximumDate = today
        initialSetupCollectionView()
        fetchObject(withDate: today)
        
   
        
    }
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        view.bringSubviewToFront(customView)
//    }
    @objc func closehdImageView(){
        isHDImageViewHiden = true
        tableView.isScrollEnabled = true
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
        cell.isUserInteractionEnabled = true
        let date = dateArray[indexPath.row]
        let dayObject = podObjectDictionary[date]
        cell.ytPlayerView?.load(withVideoId: "")
        if dayObject?.mediaType == "video" {
            cell.ytPlayerView?.isHidden = false
            cell.imageView.isHidden = true
            if let videoURL = dayObject!.imageURL, let videoID = videoURL.getVideoID() {
                print(cell.ytPlayerView)
                cell.ytPlayerView?.load(withVideoId: videoID, playerVars: playVarsDic)
                

        }
        } else {
            cell.ytPlayerView?.isHidden = true
            cell.imageView.isHidden = false
            if let image = imagesDictionary[date] {
                cell.imageView.image = image
            } else {
                cell.imageView.image = UIImage(named: "imagePlaceholder")
                cell.isUserInteractionEnabled = false
            }
            print(cell.imageView.image)
        }
//        for singleView in cell.subviews {
//                    if singleView == videoPlayerView {
//                        singleView.removeFromSuperview()
//                    }
//
//                }
//        print("Cell subviews count is \(cell.subviews.count)")
//        if imagesDictionary[date] == nil {
//            cell.ytPlayerView = nil
//            cell.imageView.image = UIImage(named: "imagePlaceholder")
//            if dayObject?.mediaType == "video" {
//                cell.imageView.image = nil
//                print("MediaType is Video in Cell")
//                videoPlayerView = YTPlayerView(frame: CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height))
//                if let videoID = dayObject!.imageURL.getVideoID() {
//                    cell.addSubview(videoPlayerView)
//                    videoPlayerView.load(withVideoId: videoID, playerVars: playVarsDic)
//                }
//            }
//        } else {
//            cell.imageView.image = imagesDictionary[date] as? UIImage
//        }
        
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sizeOfTheCell = CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        return sizeOfTheCell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("TAP!")
        isHDImageViewHiden = false
        tableView.isScrollEnabled = false
    
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
                    print("UpdateImage!")
                    self.updateImage(date: date)
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
        for index in 0...dateArray.count {
            let indexPath = IndexPath(row: index, section: 0)
            let cellOfImagesCollectionView = imagesCollectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell
            cellOfImagesCollectionView?.ytPlayerView?.pauseVideo()
        }
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
    func updateImage(date: Date) {
        guard let currentObjectImage = podObjectDictionary[date], let imageURL = currentObjectImage.imageURL else {return}
        getImage(from: imageURL) { (image) in
            if let image = image {
                print("Image is \(image)")
                self.imagesDictionary[self.currentDate] = image
            }
        }
    }
    func getImage(from urlString: String, completion: @escaping(UIImage?) -> Void){
        DispatchQueue.global().async {
            if let imageURL = URL(string: urlString), let imageData = try? Data(contentsOf: imageURL) {
                completion(UIImage(data: imageData))
            }
            else {
                print("Error retreiving image!")
            }
        }
        
     
    }
    func updateHDImage(date: Date){
        guard let currentObjectImage = podObjectDictionary[date], let imageHDURL = currentObjectImage.hdImageURL else {return}
        getImage(from: imageHDURL) { (image) in
            if let image = image {
                DispatchQueue.main.async {
                    self.hdImagesDictionary[date] = image
                }
            }
        }
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
        playerView.playVideo()
    }

}

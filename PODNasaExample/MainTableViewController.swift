//
//  MainTableViewController.swift
//  PODNasaExample
//
//  Created by TheMacUser on 20.03.2021.
import youtube_ios_player_helper
import UIKit
import Photos


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
                hdImageView.image = hdImagesDictionary[currentDate]
                print("HDImageView now is Big: \(hdImageView.image)")
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
    var imageViewScale: CGFloat = 1.0
    let maxScale: CGFloat = 2.0
    let minScale: CGFloat = 1.0
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
    var isHDImageViewHiden: Bool = true {
        didSet {
            if isHDImageViewHiden {
                hdImageScrollView.isHidden = true
            } else {
                if let image = hdImagesDictionary[currentDate] {
                    hdImageView.image = image
                } else {
                    hdImageView.image = imagesDictionary[currentDate]
                    updateHDImage(date: currentDate)
                    
                }
               // hdImageView.addGestureRecognizer(doubleTapRecognizer)
                hdImageScrollView.isHidden = false
                
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
    let hdImageScrollView = UIScrollView()
    let hdImageView = UIImageView()
    var saveHDImageAfterDownload = false
    var doubleTapRecognizer = UITapGestureRecognizer()
//    let imagesaver = ImageSaver()
    var photoAlbum: PhotoManager!
    override func viewDidLoad() {
        super.viewDidLoad()
        creatingPhotoAlbum()
        tableView.alwaysBounceVertical = false
        doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTap(gestureRecognizer:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        self.hdImageView.addGestureRecognizer(doubleTapRecognizer)
//        hdImageScrollView.addGestureRecognizer(doubleTapRecognizer)
        setupScrollView()
        setupScrollingViews()
        hdImageScrollView.isHidden = true
        hdImageScrollView.delegate = self
        hdImageScrollView.layer.backgroundColor = (UIColor.black.cgColor)
        self.hdImageScrollView.minimumZoomScale = 1.0
        self.hdImageScrollView.maximumZoomScale = 5.0
        
        let closeButton = UIButton()
        let imageSaveButton = UIButton()
        imageSaveButton.layer.cornerRadius = 25
        closeButton.layer.cornerRadius = 25
        imageSaveButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        closeButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        hdImageScrollView.addSubview(closeButton)
        hdImageScrollView.addSubview(imageSaveButton)
        imageSaveButton.translatesAutoresizingMaskIntoConstraints = false
        imageSaveButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        imageSaveButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        imageSaveButton.bottomAnchor.constraint(equalTo: hdImageScrollView.frameLayoutGuide.bottomAnchor, constant: -35 ).isActive = true
        imageSaveButton.centerXAnchor.constraint(equalTo: hdImageScrollView.frameLayoutGuide.centerXAnchor, constant: 0 ).isActive = true
        let saveButtonImage = UIImage(systemName: "square.and.arrow.down", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        imageSaveButton.setImage(saveButtonImage, for: .normal)
        imageSaveButton.addTarget(self, action: #selector(saveImage(sender: )), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        closeButton.topAnchor.constraint(equalTo: hdImageScrollView.frameLayoutGuide.topAnchor, constant: 15 ).isActive = true
        closeButton.leadingAnchor.constraint(equalTo: hdImageScrollView.frameLayoutGuide.leadingAnchor, constant: 15 ).isActive = true

        let closeButtonImage = UIImage(systemName: "multiply", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        closeButton.setImage(closeButtonImage, for: .normal)
        closeButton.addTarget(self, action: #selector(closehdImageView), for: .touchUpInside)
        
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
    @objc func dragImg(_ sender: UIPanGestureRecognizer){
        guard !(sender.view?.frame == self.view.frame) else {return}
        let translation = sender.translation(in: self.view)
        print(translation)
        print(hdImageView.frame.origin)
        hdImageView.center = CGPoint(x: hdImageView.center.x + translation.x, y: hdImageView.center.y + translation.y)
        sender.setTranslation(CGPoint.zero, in: self.view)
    }
    @objc func doubleTap(gestureRecognizer: UITapGestureRecognizer){
        print("Double tap!")
        let scale = min(hdImageScrollView.zoomScale * 2, hdImageScrollView.maximumZoomScale)
        if scale != hdImageScrollView.zoomScale {
            let point = gestureRecognizer.location(in: hdImageView)
            print(point)
            let centerPoint = hdImageView.center
//            let xOffset = point.x - centerPoint.x
//            let yOffset = point.y - centerPoint.y
            let scrollSize = hdImageScrollView.frame.size
            let size = CGSize(width: scrollSize.width / scale, height: scrollSize.height / scale)
            let origin = CGPoint(x: point.x - size.width, y: point.y - size.height)
            hdImageScrollView.zoom(to: CGRect(origin: origin, size: size), animated: true)
            //hdImageScrollView.zoom(to: CGRect(, animated: <#T##Bool#>)
        }
    }
    @objc func closehdImageView(){
        hdImageScrollView.isHidden = true
        hdImageView.image = nil
        hdImageScrollView.zoomScale = 1.0
        tableView.isScrollEnabled = true
    }
    @objc func handlePinch(sender: UIPinchGestureRecognizer){
        guard sender.view != nil else {return}
        
        if sender.state == .began || sender.state == .changed {
            var pinchScale: CGFloat = sender.scale

            if imageViewScale * pinchScale < maxScale && imageViewScale * pinchScale > minScale {
                imageViewScale *= pinchScale
                sender.view?.transform = (sender.view?.transform.scaledBy(x: pinchScale, y: pinchScale))!
            }
            sender.scale = 1.0
        }
        
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
        //hdImageScrollView.isHidden = false
        isHDImageViewHiden = false
        tableView.isScrollEnabled = false
    
    }
    func setupScrollView(){
        hdImageScrollView.translatesAutoresizingMaskIntoConstraints = false
        hdImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hdImageScrollView)
        hdImageScrollView.addSubview(hdImageView)
        hdImageView.contentMode = .scaleAspectFit
        hdImageView.isUserInteractionEnabled = true
        
        hdImageScrollView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        hdImageScrollView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        hdImageScrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        hdImageScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        hdImageScrollView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        hdImageView.centerXAnchor.constraint(equalTo: hdImageScrollView.centerXAnchor).isActive = true
        hdImageView.widthAnchor.constraint(equalTo: hdImageScrollView.widthAnchor).isActive = true
        hdImageView.topAnchor.constraint(equalTo: hdImageScrollView.topAnchor).isActive = true
        hdImageView.bottomAnchor.constraint(equalTo: hdImageScrollView.bottomAnchor).isActive = true
        hdImageView.centerYAnchor.constraint(equalTo: hdImageScrollView.centerYAnchor).isActive = true
    }
    func setupScrollingViews(){
       
    }
    override func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.hdImageView
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
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        switch state {
        case .buffering:
            print("Buffering")
        case .ended:
            print("Ended")
        case .unknown:
            print("unknowon")
        case .unstarted:
            print("unstarted")
        default:
            break
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
                print("ImageData of ImageData is \(imageData)")
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
                    if self.saveHDImageAfterDownload {
                        self.photoAlbum.save(image, completion: {_,_ in })
                    }
                    self.saveHDImageAfterDownload = false
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
    @objc func saveImage(sender: UIButton){
        let titleString = NSAttributedString(string: "Збереження", attributes: [.foregroundColor : UIColor.white, .strokeWidth : -5, .strokeColor : UIColor.white, .font : UIFont(name: "Helvetica", size: 15.0)])
        let alertController = UIAlertController(title: "", message: nil, preferredStyle: .actionSheet)
        alertController.setValue(titleString, forKey: "attributedTitle")
        let cancelAction = UIAlertAction(title: "Відмінити", style: .cancel, handler: {_ in
            UIView.animate(withDuration: 0.2) {
                sender.transform = CGAffineTransform(translationX: 0, y: 0)
            }
        })
        let imageSavingAction = UIAlertAction(title: "Менший розмір", style: .default, handler: { _ in
            UIView.animate(withDuration: 0.2) {
                sender.transform = CGAffineTransform(translationX: 0, y: 0)
            }
            if let image = self.imagesDictionary[self.currentDate] {
                self.photoAlbum.save(image, completion: {_,_ in })
                print("image saved!")
            } else {
                print("Error saving image to the Photo Album!")
            }
        })
        let hdImageSavingAction = UIAlertAction(title: "Більший розмір", style: .default, handler: { _ in
            UIView.animate(withDuration: 0.2) {
                sender.transform = CGAffineTransform(translationX: 0, y: 0)
            }
            if let image = self.hdImagesDictionary[self.currentDate]{
                self.photoAlbum.save(image, completion: {_,_ in })
            } else {
                self.saveHDImageAfterDownload = true
                print("Error saving HD image to the Photo Album!")
            }
        })
        let subview = (alertController.view.subviews.first?.subviews.first?.subviews.first!)! as UIView
        subview.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        imageSavingAction.setValue(UIColor.white, forKey: "titleTextColor")
        hdImageSavingAction.setValue(UIColor.white, forKey: "titleTextColor")
        alertController.addAction(cancelAction)
        alertController.addAction(imageSavingAction)
        alertController.addAction(hdImageSavingAction)
        
//        alertController.popoverPresentationController?.sourceView = sender
        present(alertController, animated: true, completion: nil)
        UIView.animate(withDuration: 0.2) {
            sender.transform = CGAffineTransform(translationX: 0, y: 150)
        }
//        imagesaver.writeToPhotoAlbum(image: imagesDictionary[currentDate]!)
        
        
    }
    func creatingPhotoAlbum(){
            photoAlbum = PhotoManager(albumName: "APOD pictures")
            print("Album when creating pet: \(photoAlbum)")

        }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard let indexPathOfVisibleCell = indexPathForVisibleCell else {return}
        for index in 0...dateArray.count {
            let indexPath = IndexPath(row: index, section: 0)
            let cellOfImagesCollectionView = imagesCollectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell
            cellOfImagesCollectionView?.ytPlayerView?.pauseVideo()
        }
    }
}

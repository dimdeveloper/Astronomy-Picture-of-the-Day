//
//  MainTableViewController.swift
//  PODNasaExample
//
//  Created by TheMacUser on 20.03.2021.
import youtube_ios_player_helper
import UIKit
import Photos


class MainTableViewController: UITableViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, YTPlayerViewDelegate {
    
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var chevronLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var imagesCollectionView: UICollectionView!
    @IBOutlet weak var imageName: UILabel!
    @IBOutlet weak var imageDescription: UITextView!
    
    @IBAction func datePickerDateChanged(_ sender: UIDatePicker) {
        spinner.startAnimating()
        currentDate = datePicker.date
        initialSetupCollectionView()
        setContentOffset()
    }
    let saveSpiner: UIActivityIndicatorView = {
        let spiner = UIActivityIndicatorView(style: .large)
        spiner.color = UIColor.white
        return spiner
    }()
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
    var hdImagesDictionary: [Date : UIImage] = [:] {
        didSet{
            if !isHDImageViewHiden {
                hdImageView.image = hdImagesDictionary[currentDate]
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
    let today = Date()
    lazy var currentDate = today {
        didSet {
            (imagesDictionary[currentDate] == nil) ? spinner.startAnimating() : spinner.stopAnimating()
            
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
    lazy var currentObject: PODObject = podObjectDictionary[currentDate]!
    var isHDImageViewHiden: Bool = true {
        didSet {
            updateTableViewScrollEnable()
            if isHDImageViewHiden {
                hdImageScrollView.isHidden = true
            } else {
                if let image = hdImagesDictionary[currentDate] {
                    hdImageView.image = image
                } else {
                    hdImageView.image = imagesDictionary[currentDate]
                    updateHDImage(date: currentDate)
                    
                }
                hdImageScrollView.isHidden = false
            }
        }
    }
    let defaults = UserDefaults.standard
    var hdImage = UIImageView()
    let hdImageScrollView: UIScrollView = {
       let hdImage = UIScrollView()
        hdImage.contentInsetAdjustmentBehavior = .never
        hdImage.isHidden = true
        //hdImageScrollView.layer.backgroundColor = (UIColor.black.cgColor)
        hdImage.layer.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0).cgColor
        hdImage.minimumZoomScale = 1.0
        hdImage.maximumZoomScale = 5.0
        return hdImage
    }()
    let instructionsView = UIView()
    let hdImageView = UIImageView()
    var saveHDImageAfterDownload = false
    var doubleTapRecognizer = UITapGestureRecognizer()
    var photoAlbum: PhotoManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInsetAdjustmentBehavior = .never
        loadUserDefaults()
        spinner.hidesWhenStopped = true
        spinner.startAnimating()
        creatingPhotoAlbum()
        tableView.alwaysBounceVertical = false
        updateTableViewScrollEnable()
        doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTap(gestureRecognizer:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        self.hdImageView.addGestureRecognizer(doubleTapRecognizer)
        setupScrollView()
        setupScrollingViews()
        hdImageScrollView.delegate = self
        setupInstructionsView()
        addingInstructionsView()
        chevronLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2)
        datePicker.date = today
        datePicker.maximumDate = today
        initialSetupCollectionView()
        fetchObject(withDate: today)

    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateScrollViewConstraints()
        print(tableView.isScrollEnabled)
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
            return UITableView.automaticDimension
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
            cell.imageView.isHidden = true
            if let videoURL = dayObject!.imageURL, let videoID = videoURL.getVideoID() {
                cell.ytPlayerView?.load(withVideoId: videoID, playerVars: playVarsDic)
                cell.ytPlayerView?.isHidden = false
                spinner.stopAnimating()
        }
        } else {
            cell.ytPlayerView?.isHidden = true
            cell.imageView.isHidden = false
            if let image = imagesDictionary[date] {
                cell.imageView.image = image
                spinner.stopAnimating()
            } else {
                cell.imageView.image = UIImage(named: "imagePlaceholder")
                cell.isUserInteractionEnabled = false
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sizeOfTheCell = CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        return sizeOfTheCell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        isHDImageViewHiden = false
    }
    
    func addingInstructionsView(){
        instructionsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionsView)
        NSLayoutConstraint.activate([
            instructionsView.topAnchor.constraint(equalTo: view.topAnchor),
            instructionsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            instructionsView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            instructionsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            instructionsView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            instructionsView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
    }
    func setupInstructionsView(){
        let blureffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let blurEffectView = UIVisualEffectView(effect: blureffect)
        instructionsView.addSubview(blurEffectView)
        blurEffectView.frame = instructionsView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        NSLayoutConstraint.activate([
            blurEffectView.topAnchor.constraint(equalTo: instructionsView.topAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: instructionsView.bottomAnchor),
            blurEffectView.leadingAnchor.constraint(equalTo: instructionsView.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: instructionsView.trailingAnchor),
        ])
        
        let button = UIButton()
        button.setTitle("OK", for: .normal)
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.cgColor
        button.addTarget(self, action: #selector(instructionsButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.contentView.addSubview(button)
        button.centerXAnchor.constraint(equalTo: blurEffectView.contentView.centerXAnchor).isActive = true
        button.widthAnchor.constraint(equalToConstant: 80).isActive = true
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        button.bottomAnchor.constraint(equalTo: blurEffectView.contentView.bottomAnchor, constant: -50).isActive = true
        
        let label = UILabel()
        label.text = "Ви можете змінити зображення шляхом перетягування вправо або вліво, або обрати іншу дату"
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.contentView.addSubview(label)
        label.centerXAnchor.constraint(equalTo: blurEffectView.contentView.centerXAnchor, constant: 0).isActive = true
        label.bottomAnchor.constraint(lessThanOrEqualTo: button.topAnchor, constant: -150).isActive = true
        label.bottomAnchor.constraint(greaterThanOrEqualTo: button.topAnchor, constant: -100).isActive = true
        label.leadingAnchor.constraint(equalTo: blurEffectView.contentView.leadingAnchor, constant: 100).isActive = true
        label.trailingAnchor.constraint(equalTo: blurEffectView.contentView.trailingAnchor, constant: -100).isActive = true
        
        let instructionsHandImageView = UIImageView()
        let handImage = UIImage(systemName: "hand.point.up.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .light, scale: .large))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        instructionsHandImageView.image = handImage
        instructionsHandImageView.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.contentView.addSubview(instructionsHandImageView)
        instructionsHandImageView.bottomAnchor.constraint(equalTo: label.topAnchor, constant: -50).isActive = true
        instructionsHandImageView.centerXAnchor.constraint(equalTo: blurEffectView.contentView.centerXAnchor).isActive = true
        
        let arrowLeftImageView = UIImageView()
        let leftArrowImage = UIImage(systemName: "arrow.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .light, scale: .large))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        arrowLeftImageView.image = leftArrowImage
        arrowLeftImageView.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.contentView.addSubview(arrowLeftImageView)
        arrowLeftImageView.bottomAnchor.constraint(equalTo: instructionsHandImageView.topAnchor, constant: -30).isActive = true
        arrowLeftImageView.centerXAnchor.constraint(equalTo: instructionsHandImageView.centerXAnchor, constant: -100).isActive = true
        arrowLeftImageView.topAnchor.constraint(greaterThanOrEqualTo: blurEffectView.contentView.topAnchor, constant: 10).isActive = true
        arrowLeftImageView.topAnchor.constraint(lessThanOrEqualTo: blurEffectView.contentView.topAnchor, constant: 150).isActive = true
        
        let arrowRightImageView = UIImageView()
        let rightArrowImage = UIImage(systemName: "arrow.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .light, scale: .large))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        arrowRightImageView.image = rightArrowImage
        arrowRightImageView.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.contentView.addSubview(arrowRightImageView)
        arrowRightImageView.bottomAnchor.constraint(equalTo: instructionsHandImageView.topAnchor, constant: -30).isActive = true
        arrowRightImageView.centerXAnchor.constraint(equalTo: instructionsHandImageView.centerXAnchor, constant: 100).isActive = true
        arrowRightImageView.topAnchor.constraint(greaterThanOrEqualTo: blurEffectView.contentView.topAnchor, constant: 10).isActive = true
        arrowRightImageView.topAnchor.constraint(lessThanOrEqualTo: blurEffectView.contentView.topAnchor, constant: 150).isActive = true

    }
    func setupScrollView(){
        hdImageScrollView.translatesAutoresizingMaskIntoConstraints = false
        hdImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hdImageScrollView)
        hdImageScrollView.addSubview(hdImageView)
        hdImageView.contentMode = .scaleAspectFit
        hdImageView.isUserInteractionEnabled = true
        hdImageView.addSubview(saveSpiner)
    }
    func updateScrollViewConstraints(){
        let safeAreaEdgeInsets = view.safeAreaInsets
        hdImageScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,  constant: safeAreaEdgeInsets.bottom).isActive = true
        hdImageScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        hdImageScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        hdImageScrollView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        
        hdImageView.centerXAnchor.constraint(equalTo: hdImageScrollView.centerXAnchor).isActive = true
        hdImageView.widthAnchor.constraint(equalTo: hdImageScrollView.widthAnchor).isActive = true
        hdImageView.topAnchor.constraint(equalTo: hdImageScrollView.topAnchor).isActive = true
        hdImageView.bottomAnchor.constraint(equalTo: hdImageScrollView.bottomAnchor).isActive = true
        hdImageView.centerYAnchor.constraint(equalTo: hdImageScrollView.centerYAnchor).isActive = true
        saveSpiner.translatesAutoresizingMaskIntoConstraints = false
        saveSpiner.centerXAnchor.constraint(equalTo: hdImageView.centerXAnchor).isActive = true
        saveSpiner.centerYAnchor.constraint(equalTo: hdImageView.centerYAnchor).isActive = true
    }
    func setupScrollingViews(){
        let closeButton = UIButton()
        closeButton.layer.cornerRadius = 25
        closeButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        hdImageScrollView.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        closeButton.topAnchor.constraint(equalTo: hdImageScrollView.frameLayoutGuide.topAnchor, constant: 25 ).isActive = true
        closeButton.leadingAnchor.constraint(equalTo: hdImageScrollView.frameLayoutGuide.leadingAnchor, constant: 15 ).isActive = true

        let closeButtonImage = UIImage(systemName: "multiply", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        closeButton.setImage(closeButtonImage, for: .normal)
        closeButton.addTarget(self, action: #selector(closehdImageView), for: .touchUpInside)
        let imageSaveButton = UIButton()
        imageSaveButton.layer.cornerRadius = 25
        imageSaveButton.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        hdImageScrollView.addSubview(imageSaveButton)
        imageSaveButton.translatesAutoresizingMaskIntoConstraints = false
        imageSaveButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        imageSaveButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        imageSaveButton.bottomAnchor.constraint(equalTo: hdImageScrollView.frameLayoutGuide.bottomAnchor, constant: -35 ).isActive = true
        imageSaveButton.centerXAnchor.constraint(equalTo: hdImageScrollView.frameLayoutGuide.centerXAnchor, constant: 0 ).isActive = true
        let saveButtonImage = UIImage(systemName: "square.and.arrow.down", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        imageSaveButton.setImage(saveButtonImage, for: .normal)
        imageSaveButton.addTarget(self, action: #selector(saveImage(sender: )), for: .touchUpInside)
       
    }
    override func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.hdImageView
    }
    func fetchObject(withDate date: Date){
        request.fetchNASAPOD(date: date) { object in
            if let object = object {
                DispatchQueue.main.async {
                    self.updateTableView(with: object)
                }
                self.podObjectDictionary[date] = object
                if object.mediaType == "video" {
                    DispatchQueue.main.async {
                        self.imagesCollectionView.reloadData()
                    }
                } else {
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
    }
    func setContentOffset(){
        let itemsCount = CGFloat((imagesCollectionView?.numberOfItems(inSection: 0))!)
        imagesCollectionView.setContentOffset(CGPoint(x: (imagesCollectionView.collectionViewLayout.collectionViewContentSize.width)/itemsCount*4, y: 0), animated: false)
    }
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let indexPathOfVisibleCell = indexPathForVisibleCell else {return}
        let visibleCell = imagesCollectionView.cellForItem(at: indexPathForVisibleCell!) as? ImageCollectionViewCell
        currentDate = dateArray[indexPathOfVisibleCell.row]
        print(currentDate)
        ((imagesDictionary[currentDate] == nil) && visibleCell?.ytPlayerView?.isHidden == true) ? spinner.startAnimating() : spinner.stopAnimating()
            
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
        spinner.stopAnimating()
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
                self.imagesDictionary[date] = image
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
                    if self.saveHDImageAfterDownload {
                        self.photoAlbum.save(image, completion: {_,_ in
                            DispatchQueue.main.async {
                                self.saveSpiner.stopAnimating()
                            }
                            
                        })
                    }
                    self.saveHDImageAfterDownload = false
                }
            }
        }
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard imagesCollectionView != nil else {return}
        let offset = imagesCollectionView.contentOffset
        let width = imagesCollectionView.bounds.size.width
        let index = round(offset.x/width)
        let newOffset: CGPoint = CGPoint(x: index*(size.width), y: offset.y)
        coordinator.animate ( alongsideTransition:  {(context) in
            self.imagesCollectionView.reloadData()
            self.imagesCollectionView.setContentOffset(newOffset, animated:  false)
            
        }, completion: nil)

    }

    func loadUserDefaults(){
        instructionsView.isHidden = defaults.object(forKey: "instructionsViewHidden") as? Bool ?? false
    }
    func saveUserDefaults(){
        defaults.setValue(instructionsView.isHidden, forKey: "instructionsViewHidden")
    }
    func creatingPhotoAlbum(){
            photoAlbum = PhotoManager(albumName: "APOD pictures")

        }
    func updateTableViewScrollEnable(){
        guard isHDImageViewHiden else {
            tableView.isScrollEnabled = false
            return
        }
        tableView.isScrollEnabled = (UIScreen.main.bounds.width > UIScreen.main.bounds.height) ? true : false
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        guard indexPathForVisibleCell != nil else {return}
        for index in 0...dateArray.count {
            let indexPath = IndexPath(row: index, section: 0)
            let cellOfImagesCollectionView = imagesCollectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell
            cellOfImagesCollectionView?.ytPlayerView?.pauseVideo()
        }
       updateTableViewScrollEnable()
    }
    @objc func tapFunction(){
        isDatePickerHidden = true
        view.removeGestureRecognizer(tapGesture)
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    @objc func saveImage(sender: UIButton){
        let alertController = UIAlertController(title: "", message: nil, preferredStyle: .actionSheet)
        let text = "Збереження"
        let titleString = NSMutableAttributedString(string: text)
        titleString.addAttributes([NSAttributedString.Key.foregroundColor : UIColor.white], range: NSMakeRange(0, text.count))
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
            self.saveSpiner.startAnimating()
            UIView.animate(withDuration: 0.2) {
                sender.transform = CGAffineTransform(translationX: 0, y: 0)
            }
            if let image = self.hdImagesDictionary[self.currentDate]{
                self.photoAlbum.save(image, completion: {_,_ in
                    DispatchQueue.main.async {
                        self.saveSpiner.stopAnimating()
                    }
                })
            } else {
                self.saveHDImageAfterDownload = true
                print("Error saving HD image to the Photo Album!")
            }
        })
        alertController.addAction(cancelAction)
        alertController.addAction(imageSavingAction)
        alertController.addAction(hdImageSavingAction)
        present(alertController, animated: true, completion: nil)
        UIView.animate(withDuration: 0.2) {
            sender.transform = CGAffineTransform(translationX: 0, y: 150)
        }
    }
    @objc func doubleTap(gestureRecognizer: UITapGestureRecognizer){
        let scale = min(hdImageScrollView.zoomScale * 2, hdImageScrollView.maximumZoomScale)
        if scale != hdImageScrollView.zoomScale {
            let point = gestureRecognizer.location(in: hdImageView)
            let scrollSize = hdImageScrollView.frame.size
            let size = CGSize(width: scrollSize.width / scale, height: scrollSize.height / scale)
            let origin = CGPoint(x: point.x - size.width, y: point.y - size.height)
            hdImageScrollView.zoom(to: CGRect(origin: origin, size: size), animated: true)
        }
    }
    @objc func closehdImageView(){
        isHDImageViewHiden = true
        hdImageView.image = nil
        hdImageScrollView.zoomScale = 1.0
    }
    @objc func instructionsButtonTapped(){
        instructionsView.isHidden = true
        saveUserDefaults()
    }
}

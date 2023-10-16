//
//  GalleryViewController.swift
//  Briefing Camera App
//
//  Created by Vladislav Sitsko on 16.10.23.
//

import UIKit
import SnapKit
import Photos

class GalleryViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private static let defaultSpacing: CGFloat = 20.0
    
    private lazy var cameraButtton = UIButton()
    private lazy var galleryTitleLabel = UILabel()
    private lazy var bottomView = UIView()
    private lazy var activityIndicator = UIActivityIndicatorView(style: .large)
    
    private lazy var cancelSelectionButton: UIButton = {
        let button = UIButton()
        button.isHidden = true
        button.setImage(UIImage(named: "cancel"), for: .normal)
        button.addTarget(self, action: #selector(cancelAll), for: .touchUpInside)
        return button
    }()
    
    private lazy var deleteSelectionButton: UIButton = {
        let button = UIButton()
        button.isHidden = true
        button.setImage(UIImage(named: "delete"), for: .normal)
        button.addTarget(self, action: #selector(deleteSelected), for: .touchUpInside)
        return button
    }()
    
    private var collectionView: UICollectionView?
    
    private let viewModel = GalleryViewModel()
    
    private var editMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        setupViews()
        setupConstraints()
        
        viewModel.updateCompletion = { [weak self] in
            guard let self else { return }
            self.collectionView?.reloadData()
            self.activityIndicator.stopAnimating()
        }
        
        viewModel.loadPhotos()
    }
}

// MARK: - private

private extension GalleryViewController {
    
    func configureCollectionView() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 140, right: 0)
        layout.minimumLineSpacing = Self.defaultSpacing
        
        let edge = (UIScreen.main.bounds.width - (Self.defaultSpacing * 3)) / 2
        layout.itemSize = CGSize(width: edge, height: edge)
        
        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        
        collectionView?.register(
            GalleryCollectionViewCell.self,
            forCellWithReuseIdentifier: String(describing: GalleryCollectionViewCell.self)
        )
        collectionView?.register(
            UICollectionViewCell.self,
            forCellWithReuseIdentifier: String(describing: UICollectionViewCell.self)
        )
        
        collectionView?.backgroundColor = .white
        collectionView?.dataSource = self
        collectionView?.delegate = self
        view.addSubview(collectionView ?? UICollectionView())
    }
}

// MARK: - SetupViews

private extension GalleryViewController {
    func setupViews() {
        view.backgroundColor = .white
        
        activityIndicator.tintColor = Color.darkRedColor
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        
        galleryTitleLabel.textColor = Color.textBlackColor
        galleryTitleLabel.font = UIFont.systemFont(ofSize: 30, weight: .medium)
        galleryTitleLabel.text = "Alle Bilder"
        view.addSubview(galleryTitleLabel)
        
        bottomView.backgroundColor = Color.lightRedColor
        bottomView.layer.cornerRadius = 10
        bottomView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        view.addSubview(bottomView)
        
        bottomView.addSubview(cancelSelectionButton)
        bottomView.addSubview(deleteSelectionButton)
        
        cameraButtton.setImage(UIImage(named: "photoIcon"), for: .normal)
        
        cameraButtton.addTarget(
            self, action: #selector(cameraButttonPressed),
            for: .touchUpInside
        )
        
        bottomView.addSubview(cameraButtton)
        
        let longPress = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress(sender:))
        )
        collectionView?.addGestureRecognizer(longPress)
    }
}


// MARK: - SetupConstraints

private extension GalleryViewController {
    func setupConstraints() {
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        galleryTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(43)
            make.leading.equalToSuperview().offset(Self.defaultSpacing)
        }
        
        bottomView.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview()
            make.height.equalTo(108)
        }
        
        cameraButtton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(70)
        }
        
        cancelSelectionButton.snp.makeConstraints { make in
            make.size.equalTo(60)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(view.snp.centerX).offset(-16)
        }
        
        deleteSelectionButton.snp.makeConstraints { make in
            make.size.equalTo(60)
            make.centerY.equalToSuperview()
            make.leading.equalTo(view.snp.centerX).offset(16)
        }
        
        collectionView?.snp.makeConstraints { make in
            make.top.equalTo(galleryTitleLabel.snp.bottom).offset(Self.defaultSpacing)
            make.leading.trailing.equalToSuperview().inset(Self.defaultSpacing)
            make.bottom.equalToSuperview()
        }
    }
}

// MARK: - Action

@objc private extension GalleryViewController {
    func cameraButttonPressed() {
        dismiss(animated: true)
    }
    
    func handleLongPress(sender: UILongPressGestureRecognizer) {
        guard !editMode else { return }
        
        switch sender.state {
        case .possible:
            print("possible")
        case .began:
            let touchPoint = sender.location(in: collectionView)
            if let indexPath = collectionView?.indexPathForItem(at: touchPoint) {
                editMode = true
                viewModel.updateSelection(for: indexPath.row)
                collectionView?.reloadData()
                toggleEditButtons()
            }
        case .changed:
            print("changed")
        case .ended:
            print("ended")
        case .cancelled:
            print("cancelled")
        case .failed:
            print("failed")
        @unknown default:
            print("unknown")
        }
    }
    
    @objc func cancelAll() {
        editMode = false
        viewModel.deselectAll()
        collectionView?.reloadData()
        toggleEditButtons()
    }
    
    func toggleEditButtons() {
        cameraButtton.isHidden = editMode
        cancelSelectionButton.isHidden = !editMode
        deleteSelectionButton.isHidden = !editMode
    }
    
    @objc func deleteSelected() {
        viewModel.deleteSelected()
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource

extension GalleryViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: String(describing: GalleryCollectionViewCell.self),
                for: indexPath
            ) as? GalleryCollectionViewCell
        else  {
            return UICollectionViewCell()
        }
        
        cell.setup(with: viewModel.photos[indexPath.row])
        cell.editMode = editMode
        
        cell.updateSelection = { [weak self] in
            self?.viewModel.updateSelection(for: indexPath.row)
        }
        
        return cell
    }
}

//
//  GalleryViewModel.swift
//  Briefing Camera App
//
//  Created by Vladislav Sitsko on 16.10.23.
//

import UIKit
import Photos

class GalleryViewModel: NSObject {
    private var assetsFetchResult = PHFetchResult<PHAsset>()
    private(set) var photos = [GalleryItemModel]()
    private let dispatchGroup = DispatchGroup()
    
    private lazy var manager = PHImageManager.default()
    
    private lazy var requestOptions: PHImageRequestOptions = {
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat
        return requestOptions
    }()
    
    private lazy var fetchOptions: PHFetchOptions = {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return fetchOptions
    }()
    
    private static let size = CGSize(width: 250, height: 250)
    
    var updateCompletion: (() -> ())?
    
    override init() {
        super.init()
        
        PHPhotoLibrary.shared().register(self)
    }
    
    func loadPhotos() {
        PHPhotoLibrary.requestAuthorization { [weak self] (status) in
            guard let self, status == .authorized else {
                self?.updateCompletion?()
                return
            }
            
            self.assetsFetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            
            guard self.assetsFetchResult.count > 0 else {
                updateCompletion?()
                return
            }
            
            self.photos = []
            for i in 0..<self.assetsFetchResult.count {
                self.dispatchGroup.enter()
                
                manager.requestImage(
                    for: self.assetsFetchResult.object(at: i),
                    targetSize: Self.size,
                    contentMode: .aspectFill,
                    options: requestOptions
                ) { (image, _) in
                    defer { self.dispatchGroup.leave() }
                    guard let image = image else { return }
                    self.photos.append(
                        GalleryItemModel(image: image, isSelected: false)
                    )
                }
            }
            
            self.dispatchGroup.notify(queue: .main) {
                self.updateCompletion?()
            }
        }
    }
    
    func updateSelection(for index: Int) {
        photos[index].isSelected.toggle()
    }
    
    func deselectAll() {
        photos.enumerated().forEach { i, _ in
            photos[i].isSelected = false
        }
    }
    
    func deleteSelected() {
        let indexes = photos.enumerated().compactMap { $0.element.isSelected ? $0.offset : nil }
        
        guard !indexes.isEmpty else { return }
        let assetsToDelete = assetsFetchResult.objects(at: IndexSet(indexes))
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assetsToDelete as NSFastEnumeration)
        }, completionHandler: { [weak self] _, _  in
            DispatchQueue.main.async {
                self?.updateCompletion?()
            }
        })
    }
}

extension GalleryViewModel: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        let fetchResultChangeDetails = changeInstance.changeDetails(for: assetsFetchResult)
        guard let fetchResultChangeDetails else { return }
        
        assetsFetchResult = fetchResultChangeDetails.fetchResultAfterChanges
        let insertedObjects = fetchResultChangeDetails.insertedObjects
        let removedObjects = fetchResultChangeDetails.removedObjects
        
        if !insertedObjects.isEmpty || !removedObjects.isEmpty {
            loadPhotos()
        }
    }
}

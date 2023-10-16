//
//  GalleryCollectionViewCell.swift
//  Briefing Camera App
//
//  Created by Vladislav Sitsko on 16.10.23.
//

import UIKit

class GalleryCollectionViewCell: UICollectionViewCell {
    private lazy var imageView = UIImageView()
    private lazy var checkMarkButton = UIButton()
    
    var updateSelection: (() -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    var editMode = false {
        didSet {
            checkMarkButton.isHidden = !editMode
        }
    }
    
    private var selectedMode = false {
        didSet {
            checkMarkButton.isSelected = selectedMode
        }
    }
    
    func setup(with model: GalleryItemModel) {
        imageView.image = model.image
        selectedMode = model.isSelected
    }
    
    @objc func changeSelection() {
        selectedMode.toggle()
        updateSelection?()
    }
}

private extension GalleryCollectionViewCell {
    func commonInit() {
        setupViews()
        setupConstraints()
    }
    
    func setupCheckmark() {
        checkMarkButton.isHidden = true
        checkMarkButton.addTarget(
            self, action: #selector(changeSelection),
            for: .touchUpInside
        )
        
        checkMarkButton.setImage(UIImage(named: "checkmarkSelected"), for: .selected)
        checkMarkButton.setImage(UIImage(named: "checkmarkEmpty"), for: .normal)
        checkMarkButton.layer.shadowColor = UIColor.black.cgColor
        checkMarkButton.layer.shadowOpacity = 1.0
        checkMarkButton.layer.shadowOffset = .zero
        
        addSubview(checkMarkButton)
    }
    
    func setupImageView() {
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        
        addSubview(imageView)
    }
    
    func setupViews() {
        setupImageView()
        setupCheckmark()
    }
    
    func setupConstraints() {
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        checkMarkButton.snp.makeConstraints { make in
            make.size.equalTo(40)
            make.trailing.top.equalToSuperview().inset(10)
        }
    }
}


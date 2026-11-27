// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Collection view for the NTP that fully re-lays out its sections whenever its size changes.
///
/// The impact section is sized from the container height so TopSites sit right above the omnibox.
/// A size change alone only partially invalidates a compositional layout, which keeps the
/// self-sized impact cell at the height it had before. Swiping back from the SERP lays the NTP
/// out while the address bar is still on screen, so the impact cell kept that shorter height and
/// TopSites stayed shifted up once the address bar was gone. Invalidating the whole layout on
/// every size change resizes the cell for the final container, whenever the size settles.
final class NTPCollectionView: UICollectionView {

    private var lastLaidOutSize: CGSize = .zero

    override func layoutSubviews() {
        if bounds.size != lastLaidOutSize {
            lastLaidOutSize = bounds.size
            collectionViewLayout.invalidateLayout()
        }
        super.layoutSubviews()
    }
}

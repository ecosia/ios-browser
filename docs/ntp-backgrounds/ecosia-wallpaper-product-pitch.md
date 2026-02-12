# Ecosia Wallpaper System - Product Pitch

## Problem Statement

Currently, Ecosia's iOS app does not offer homepage wallpaper customization, missing an opportunity to:
- ❌ Provide users with personalization options
- ❌ Showcase Ecosia's nature-focused brand through beautiful imagery
- ❌ Create an engaging, delightful user experience
- ❌ Leverage Firefox's existing wallpaper infrastructure

Meanwhile, Firefox iOS has a sophisticated wallpaper system that's already built and ready to use.

## Opportunity

Firefox iOS has a sophisticated wallpaper system that supports:
- ✅ Multiple wallpaper options
- ✅ Orientation-specific images (portrait vs landscape)
- ✅ Device-specific images (iPhone vs iPad)
- ✅ User customization through settings
- ✅ Beautiful UI for wallpaper selection
- ✅ Proper color theming (text, cards, logos)

**We can reuse this entire system with Ecosia-branded assets.**

## Proposed Solution

Leverage Firefox's existing wallpaper infrastructure with Ecosia-hosted wallpaper assets.

**Key insight**: Firefox already has everything we need - UI, download logic, caching, settings integration. We just need to host Ecosia wallpapers and point the app to our server. **Zero code changes required.**

### User Experience

**Current Experience:**
1. User opens new tab
2. Sees default homepage with no background imagery
3. No customization options available

**Proposed Experience:**
1. User opens new tab
2. Sees a beautiful, orientation-optimized Ecosia wallpaper
3. Can navigate to Settings → Homepage → Wallpapers
4. Chooses from multiple Ecosia nature-themed wallpapers
5. Wallpaper adapts perfectly to device orientation (portrait/landscape)
6. Wallpaper optimized for device type (iPhone/iPad)

### Visual Concept

#### Wallpaper Collection: "Ecosia Nature"

**Example wallpapers:**
1. **Forest Canopy** - Lush green forest from below
2. **Ocean Waves** - Calm ocean with subtle waves
3. **Mountain Vista** - Distant mountains with morning mist
4. **Wildflower Meadow** - Colorful wildflowers in a field
5. **Desert Sunset** - Warm desert landscape at golden hour

Each wallpaper would have:
- **Text color** optimized for readability
- **Card background color** that complements the image
- **Logo color** that stands out appropriately

### Technical Benefits

#### For Users
- **Better visual experience** - Images optimized for each orientation
- **Personalization** - Choose their favorite Ecosia wallpaper
- **Performance** - No download required, works offline immediately
- **Consistency** - Same wallpaper system as Firefox users expect

#### For Ecosia
- **Brand consistency** - Wallpapers that align with Ecosia's nature-focused brand
- **Reusable infrastructure** - Leverages existing, tested Firefox code (zero code changes!)
- **Low cost** - Minimal CDN bandwidth (~10-15 MB per user one-time)
- **Maintainability** - Easy to add new wallpapers without app updates
- **Quality** - Professional wallpaper selector UI already built
- **Fast to market** - 2 weeks from design to launch

## Asset Requirements

### What Designers Need to Create

For **each wallpaper**, we need 4 images:

| Image | Device | Orientation | Dimensions | Filename Format |
|-------|--------|-------------|------------|-----------------|
| 1 | iPhone | Portrait | 1170 × 2532 px | `{id}_iPhone_portrait.jpg` |
| 2 | iPhone | Landscape | 2532 × 1170 px | `{id}_iPhone_landscape.jpg` |
| 3 | iPad | Portrait | 2048 × 2732 px | `{id}_iPad_portrait.jpg` |
| 4 | iPad | Landscape | 2732 × 2048 px | `{id}_iPad_landscape.jpg` |

**File format**: JPG (85% quality, optimized for web delivery)
**File size target**: ~500KB - 1MB per image (~2-4 MB total per wallpaper)

**Plus for each wallpaper:**
- **Text color** (hex code) - for readable text overlay
- **Card color** (hex code) - for semi-transparent card backgrounds
- **Logo color** (hex code) - for Ecosia logo

### Design Considerations

1. **Composition**: Each orientation should be composed specifically for that aspect ratio (not just cropped)
2. **Safe areas**: Keep important visual elements within safe areas to avoid UI overlap
3. **Readability**: Ensure text remains readable with chosen text colors
4. **Brand alignment**: Images should reflect Ecosia's environmental mission
5. **Variety**: Offer diverse scenes (forest, ocean, mountains, etc.)

### Example Metadata

```json
{
  "id": "ecosia-forest",
  "text-color": "FFFFFF",
  "card-color": "2D4A2B",
  "logo-text-color": "E8F5E9"
}
```

## Implementation Timeline

| Phase | Duration | Description |
|-------|----------|-------------|
| **Design** | 1 week | Create 3-5 wallpapers (4 images each) + color schemes |
| **Engineering** | 1.5 weeks | Implement bundled asset loading system |
| **Testing** | 0.5 weeks | QA on various devices and orientations |
| **Total** | **3 weeks** | From kickoff to release-ready |

## Success Metrics

### Quantitative
- **Wallpaper engagement rate** - % of users who change their wallpaper
- **Settings visits** - Increase in Settings → Wallpaper page views
- **User retention** - Correlation between wallpaper customization and retention

### Qualitative
- **User feedback** - Reviews mentioning customization/wallpapers
- **Brand perception** - Alignment with Ecosia's nature-focused brand
- **Visual quality** - Professional appearance across all devices

## Competitive Analysis

| Browser | Wallpaper Support | Notes |
|---------|------------------|-------|
| **Firefox** | ✅ Full system | Multiple wallpapers, downloads from server |
| **Safari** | ❌ None | Static default background |
| **Chrome iOS** | ❌ None | Static default background |
| **Edge iOS** | ❌ None | Static default background |
| **Ecosia (current)** | ❌ None | No wallpaper support |
| **Ecosia (proposed)** | ✅ Full system | Multiple bundled wallpapers |

**Differentiator**: Ecosia would join Firefox as one of the few iOS browsers offering wallpaper customization, while maintaining offline-first functionality.

## User Stories

### Story 1: First-Time User
> "As a new Ecosia user, I want to see a beautiful nature-themed background when I open a new tab, so I feel connected to Ecosia's environmental mission."

### Story 2: Personalization Enthusiast
> "As a user who values customization, I want to choose from multiple Ecosia wallpapers, so I can personalize my browsing experience."

### Story 3: Orientation Switcher
> "As an iPad user who frequently rotates my device, I want wallpapers that look great in both portrait and landscape, so my experience is always optimal."

### Story 4: Offline User
> "As a user with limited connectivity, I want wallpapers to work immediately without downloading, so I don't waste data or wait for assets to load."

## Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|-----------|
| **App size increase** | Medium | Each wallpaper set ~8-15 MB; limit initial launch to 3-5 wallpapers |
| **Design resources** | Low | Clear specifications provided; existing Firefox UI patterns to follow |
| **User confusion** | Low | Reuses familiar Firefox wallpaper UI; intuitive selection interface |
| **Testing complexity** | Medium | Clear testing matrix provided; leverage Firefox's existing test coverage |

## Future Enhancements

Once the system is in place, we can:
1. **Seasonal wallpapers** - Special collections for holidays/seasons
2. **Dynamic wallpapers** - Update via app updates
3. **Community wallpapers** - User-submitted nature photography
4. **Tree counter integration** - Show tree count on wallpaper
5. **Impact statistics** - Display environmental impact on background

## Decision Points

### For Product Manager
- [ ] How many wallpapers should we launch with? (Recommendation: 3-5)
- [ ] Should wallpaper selection be promoted in onboarding?
- [ ] Do we want to track wallpaper engagement metrics?
- [ ] Should we A/B test wallpaper impact on retention?

### For Designer
- [ ] What nature themes align best with Ecosia brand?
- [ ] Should we support light/dark mode variants?
- [ ] Do we need placeholder/loading states?
- [ ] What text color overlays work best for readability?

### For Engineering
- [ ] Should we support Firefox's downloaded wallpapers as well?
- [ ] Do we need a migration path for existing users?
- [ ] Should we create an ADR for this architecture decision?

## Next Steps

1. **Kickoff meeting** - Align on scope and wallpaper themes
2. **Design sprint** - Create 3-5 initial wallpapers
3. **Engineering spike** - Validate bundled asset approach (2 days)
4. **Implementation** - Build and test (1.5 weeks)
5. **Beta testing** - Internal dogfooding
6. **Release** - Ship with next app update

## Questions?

- Technical details: See [Implementation Plan](./ecosia-wallpaper-system-implementation-plan.md)
- Architecture analysis: See [Wallpaper Configuration Analysis](./wallpaper-configuration-analysis.md)

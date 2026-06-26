# Hướng dẫn vẽ lại Muscle Assets

## Tình huống hiện tại

Ứng dụng hiện dùng:
- **PNG masks** (`assets/body/masks/`) - ảnh PNG đơn giản để highlight các nhóm cơ bắp
- **Background silhouette** (`assets/body/body_front.png`, `body_back.png`)
- Dùng `colorBlendMode: BlendMode.srcIn` để tô màu các mask

## Vấn đề

1. Các mask hiện tại quá đơn giản, không có depth hay detail
2. UI tiến độ cơ bắp nhìn chưa chuyên nghiệp lắm
3. Các tier color không nổi bật đủ

## Giải pháp cải thiện

### 1. **Nâng cấp UI widgets** ✅ (Đã hoàn tất)

**File:** `lib/features/home/widgets/muscle_progress_painter.dart`

Đã tạo các custom widgets:
- `MuscleProgressBar` - progress bar với gradient & glow effect
- `MuscleLevel` - level badge chuyên nghiệp với tier color
- `MuscleIconContainer` - container với gradient background

**Lợi ích:**
- ✨ Progress bar nhìn mượt mà, có gradient lighting
- 🎯 Level badge có border glow & animation support
- 📱 Dễ tùy chỉnh màu sắc theo tier

### 2. **Vẽ lại Muscle Assets** (Khuyến nghị)

#### Option A: Dùng Figma (Khuyên dùng)
1. Mở Figma → Tạo project mới
2. Import hiện tại `body_front.png` + `body_back.png` làm reference
3. **Vẽ các muscle groups:**
   - Dùng Path tools để tạo outline smooth
   - Thêm **subtle gradient** để tạo depth (từ darker edge đến lighter center)
   - Thêm **stroke** màu tối ở edge để tạo definition
   - Export từng muscle group riêng (PNG với transparent background)

**Muscles cần vẽ:**

**Front View:**
- `front_chest.png` - hình lỡm đôi, gradient từ trong ra ngoài
- `front_biceps.png` - hình cong tự nhiên
- `front_quads.png` - 4 ô cơ to
- `front_abs.png` - 6 pack, có ridge lines
- `front_core.png` - vùng lõi bụng
- `front_forearms.png` - cẳng tay
- `front_shoulders_anterior.png` - vai trước
- `front_shoulders_lateral.png` - vai bên
- `front_adductors.png` - cơ trong đùi
- `front_calves.png` - bắp chân trước
- `front_obliques.png` - cơ xiên bụng

**Back View:**
- `back_lats.png` - lưng rộng, hình cánh
- `back_traps.png` - thang lưng, hình thang
- `back_triceps.png` - 3 đầu tay sau
- `back_hamstrings.png` - cơ sau đùi
- `back_glute.png` - mông
- `back_shoulders_posterior.png` - vai sau
- `back_rhomboids.png` - cơ hình thoi
- `back_teres_major.png` - cơ tròn lớn
- `back_calves.png` - bắp chân sau

**Design tips:**
- Dùng **consistent stroke width** (2-3px) cho all edges
- **Gradient direction** nên theo chiều tự nhiên của cơ bắp
- Thêm **subtle texture** nếu muốn (linen pattern) để tăng realism
- Làm asset ở kích thước lớn (2x hoặc 3x) rồi export để có quality tốt

#### Option B: Dùng Illustration Tool (Procreate, Adobe Illustrator)
1. Vẽ tay từng muscle group
2. Scan/digitize
3. Refine trong Illustrator hoặc Affinity Designer
4. Export PNG tại @2x resolution

#### Option C: AI/Generated Assets
1. Dùng Midjourney/DALL-E: `"anatomical muscle diagram, clean lines, professional medical illustration, {muscle name}, transparent background"`
2. Refine kết quả bằng Photoshop/Figma

### 3. **Cải thiện Color System**

**Hiện tại:** Dùng tier colors (Bronze, Silver, Gold, Platinum, Diamond)

**Đề xuất thêm:**
```dart
// File: app_colors.dart (thêm)
static const muscleColors = {
  'tier_iron': Color(0xFF808080),      // xám
  'tier_bronze': Color(0xFFCD7F32),    // đồng
  'tier_silver': Color(0xFFA8A8A8),    // bạc
  'tier_gold': Color(0xFFFFCC00),      // vàng
  'tier_platinum': Color(0xFFE2E8F0),  // bạch kim (xám xanh nhạt)
  'tier_diamond': Color(0xFF00D9FF),   // xanh cyan (primary)
  'tier_champion': Color(0xFF9C27B0),  // tím (thêm mới)
};
```

### 4. **Animation Enhancement**

Các widget đã support animation, có thể thêm:

```dart
// Ví dụ: Pulse effect khi muscle lagging
class MuscleProgressItem extends StatefulWidget {
  // ... 
  @override
  State<MuscleProgressItem> createState() => _MuscleProgressItemState();
}

class _MuscleProgressItemState extends State<MuscleProgressItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  // Dùng _controller.view trong Opacity/Scale widget
}
```

## Implementation Roadmap

### Phase 1: UI Improvements ✅ COMPLETE
- [x] Custom progress bar painter
- [x] Professional level badges
- [x] Gradient icon containers
- [x] Update muscle_progress_card.dart
- [x] Update muscle_detail_screen.dart

### Phase 2: Asset Redesign (Recommended)
- [ ] Design muscle masks trong Figma
- [ ] Export @2x resolution
- [ ] Replace PNG files trong `assets/body/masks/`
- [ ] Test visual appearance

### Phase 3: Advanced Features (Optional)
- [ ] Add muscle detail screen với 3D model (nếu có budget)
- [ ] Add progress animation transitions
- [ ] Add lagging muscle pulse effect

## File Changes Made

1. **NEW:** `lib/features/home/widgets/muscle_progress_painter.dart`
   - MuscleProgressBar widget
   - MuscleLevel badge
   - MuscleIconContainer
   - Custom progress painter

2. **UPDATED:** `lib/features/home/widgets/muscle_progress_card.dart`
   - Import new widgets
   - Update _MuscleProgressItem to use custom widgets

3. **UPDATED:** `lib/features/home/screens/muscle_detail_screen.dart`
   - Import new widgets
   - Update _MuscleListItem to use custom widgets

## Testing Checklist

- [ ] Run app, verify no compilation errors
- [ ] Check muscle progress cards render correctly
- [ ] Verify colors match tier system
- [ ] Test with different progress values (0%, 50%, 100%)
- [ ] Check lagging indicator visibility
- [ ] Verify layout responsive on different screen sizes

## Next Steps

1. **Short term:** Test current UI improvements (done)
2. **Medium term:** Redesign muscle assets in Figma (2-3 days work)
3. **Long term:** Add interactive 3D muscle model (nice-to-have)

---

**Questions?** Check Flutter CustomPaint docs at: https://flutter.dev/docs/development/ui/advanced/custom-paint

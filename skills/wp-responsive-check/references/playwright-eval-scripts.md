# Bộ Script Tự Động Đánh Giá Responsive Bằng Playwright MCP (Evaluation Scripts)

Các đoạn mã JavaScript được tối ưu để thực thi qua công cụ `browser_evaluate` của Playwright MCP nhằm phát hiện lỗi giao diện nhanh chóng, chính xác.

---

## 1. Phát Hiện Phần Tử Gây Tràn Ngang (Horizontal Overflow Detector)

Chạy script này trên `browser_evaluate` ở các breakpoint mobile (320px, 375px, 768px):

```javascript
(() => {
  const docWidth = document.documentElement.clientWidth;
  const elements = document.querySelectorAll('*');
  const overflowing = [];

  elements.forEach(el => {
    const rect = el.getBoundingClientRect();
    if (rect.right > docWidth || rect.width > docWidth) {
      overflowing.push({
        tag: el.tagName.toLowerCase(),
        id: el.id || null,
        className: el.className || null,
        width: Math.round(rect.width),
        overflowPixels: Math.round(rect.right - docWidth)
      });
    }
  });

  return {
    hasHorizontalScroll: document.documentElement.scrollWidth > docWidth,
    docWidth: docWidth,
    scrollWidth: document.documentElement.scrollWidth,
    overflowCount: overflowing.length,
    topOverflowElements: overflowing.slice(0, 10)
  };
})()
```

---

## 2. Kiểm Tra Kích Thước Vùng Chạm Cảm Ứng (Touch Target Size < 44x44px)

Kiểm tra nút bấm, thẻ `<a>`, input trên mobile có đạt kích thước tối thiểu 44x44px (chuẩn Apple & Google) hay không:

```javascript
(() => {
  const interactive = document.querySelectorAll('button, a, input, select, textarea, [role="button"]');
  const smallTargets = [];

  interactive.forEach(el => {
    // Chỉ kiểm tra phần tử đang hiển thị
    const style = window.getComputedStyle(el);
    if (style.display === 'none' || style.visibility === 'hidden' || style.opacity === '0') return;

    const rect = el.getBoundingClientRect();
    if (rect.width > 0 && rect.height > 0) {
      if (rect.width < 44 || rect.height < 44) {
        smallTargets.push({
          tag: el.tagName.toLowerCase(),
          text: (el.innerText || el.value || '').trim().slice(0, 30),
          width: Math.round(rect.width),
          height: Math.round(rect.height),
          className: el.className || null
        });
      }
    }
  });

  return {
    totalInteractive: interactive.length,
    smallTargetCount: smallTargets.length,
    examples: smallTargets.slice(0, 10)
  };
})()
```

---

## 3. Kiểm Tra Cỡ Chữ Body Nhỏ Hơn 14px Trên Mobile

```javascript
(() => {
  const textElements = document.querySelectorAll('p, span, li, a, td, th');
  const tinyTexts = [];

  textElements.forEach(el => {
    const style = window.getComputedStyle(el);
    if (style.display === 'none' || style.visibility === 'hidden') return;
    
    const fontSize = parseFloat(style.fontSize);
    if (fontSize > 0 && fontSize < 13 && el.innerText.trim().length > 5) {
      tinyTexts.push({
        tag: el.tagName.toLowerCase(),
        text: el.innerText.trim().slice(0, 40),
        fontSize: fontSize + 'px',
        className: el.className || null
      });
    }
  });

  return {
    tinyTextCount: tinyTexts.length,
    examples: tinyTexts.slice(0, 10)
  };
})()
```

---

## 4. Kiểm Tra Ảnh Không Có `max-width: 100%`

```javascript
(() => {
  const images = document.querySelectorAll('img');
  const unconstrainedImages = [];

  images.forEach(img => {
    const style = window.getComputedStyle(img);
    if (style.maxWidth === 'none' && style.width !== '100%') {
      const rect = img.getBoundingClientRect();
      if (rect.width > document.documentElement.clientWidth) {
        unconstrainedImages.push({
          src: img.src.split('/').pop(),
          width: Math.round(rect.width),
          maxWidth: style.maxWidth
        });
      }
    }
  });

  return {
    unconstrainedCount: unconstrainedImages.length,
    images: unconstrainedImages
  };
})()
```

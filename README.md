# IT Consulting & Training Website

A modern, professional website for IT consulting and training services, featuring a dynamic design with smooth navigation and responsive layout.

## Features

- **Modern Design**: Clean, professional layout with smooth animations
- **Company Colors**: Built around your brand colors (#393185 and #25b9ce)
- **Responsive**: Fully responsive design that works on all devices
- **Dynamic Navigation**: Smooth scrolling menu bar with active state indicators
- **Section-Based Layout**: Easy navigation between About, Courses, Tech Vlogs, Downloads, and Contact

## Sections

### 1. About
- Company description
- Logo placeholder (300x300px recommended)
- Tech stack showcase (Networking, Cloud, Security, Programming)

### 2. Courses
- YouTube video embeds for course content
- Grid layout for multiple courses
- Link to full YouTube channel

### 3. Tech Vlogs
- Similar layout to Courses section
- YouTube video embeds for tech content
- Professional video presentation

### 4. Downloads
- Grid of downloadable resources
- Guides and training materials
- Clear call-to-action buttons

### 5. Contact
- Contact information display
- Contact form
- Social media links (YouTube, Instagram, TikTok, Facebook)

## Customization Guide

### Adding Your Logo

1. Replace the logo placeholder in `index.html` (around line 92-96):
```html
<div class="logo-placeholder">
    <div class="logo-box">
        <img src="your-logo.png" alt="Company Logo" style="max-width: 100%; max-height: 100%;">
    </div>
</div>
```

### Adding YouTube Videos

1. **For Courses section** (line 127-143 in index.html):
   - Replace `YOUR_PLAYLIST_ID_1`, `YOUR_PLAYLIST_ID_2`, etc. with your actual YouTube playlist IDs
   - Or use individual video IDs: `https://www.youtube.com/embed/VIDEO_ID`

2. **For Tech Vlogs section** (line 170-186):
   - Same process as Courses section

3. **YouTube Channel Link** (line 150):
   - Replace `@YourChannel` with your actual YouTube channel handle

### Updating Contact Information

In the Contact section (lines 241-271), update:
- Email address
- Phone number
- Physical address
- Business hours

### Social Media Links

Update social media URLs (lines 294-328):
- YouTube: Line 295
- Instagram: Line 304
- TikTok: Line 313
- Facebook: Line 322

### Adding Download Links

For each download card (lines 202-237), add actual file links:
```html
<a href="path/to/your/file.pdf" class="download-button" download>Download PDF</a>
```

### Customizing Colors

The website uses CSS variables defined in `styles.css` (lines 10-11):
```css
--primary-color: #393185;
--secondary-color: #25b9ce;
```

You can adjust these if needed, though they're designed to match your logo.

### Customizing Text Content

1. **Company Description**: Lines 91-123 in index.html
2. **Course Titles/Descriptions**: Lines 127-155
3. **Tech Vlog Titles/Descriptions**: Lines 170-196
4. **Download Resources**: Lines 202-237

## File Structure

```
cloudscrapers-website/
├── index.html          # Main HTML file
├── styles.css          # All styling and design
├── script.js           # JavaScript for interactivity
└── README.md           # This file
```

## How to Use

1. **Open Locally**:
   - Simply open `index.html` in your web browser
   - All files must be in the same directory

2. **Deploy to Web Server**:
   - Upload all files to your web hosting
   - Ensure file permissions are set correctly
   - Access via your domain name

3. **GitHub Pages** (if using GitHub):
   - Push to a GitHub repository
   - Enable GitHub Pages in repository settings
   - Select the main branch as source

## Browser Compatibility

- Chrome (recommended)
- Firefox
- Safari
- Edge
- Mobile browsers (iOS Safari, Chrome Mobile)

## Technical Details

### Technologies Used
- HTML5
- CSS3 (with CSS Grid and Flexbox)
- Vanilla JavaScript (no frameworks required)
- Google Fonts (Inter)

### Features
- Smooth scrolling navigation
- Mobile hamburger menu
- Scroll-triggered animations
- Active navigation state tracking
- Responsive design (mobile-first approach)
- Form validation

## Tips for Best Results

1. **Logo**: Use a transparent PNG for best results
2. **Images**: Optimize images before uploading for faster loading
3. **Videos**: Use YouTube playlists to organize content
4. **Downloads**: Host PDF files in the same directory or use cloud storage links
5. **Testing**: Test on multiple devices and browsers

## Need Help?

If you need to make changes:
- HTML structure: Edit `index.html`
- Visual design: Edit `styles.css`
- Functionality: Edit `script.js`

## License

This website template is created for your IT consulting business. Feel free to modify and customize as needed.

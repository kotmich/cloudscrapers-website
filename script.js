// ========================================
// Navigation Menu & Mobile Toggle
// ========================================

const hamburger = document.getElementById('hamburger');
const navMenu = document.getElementById('navMenu');
const navLinks = document.querySelectorAll('.nav-link');

// Toggle mobile menu
hamburger.addEventListener('click', () => {
    navMenu.classList.toggle('active');
    hamburger.classList.toggle('active');
});

// Close mobile menu when clicking a nav link
navLinks.forEach(link => {
    link.addEventListener('click', () => {
        navMenu.classList.remove('active');
        hamburger.classList.remove('active');
    });
});

// ========================================
// Dark Mode Toggle
// ========================================

const themeToggle = document.getElementById('themeToggle');
const body = document.body;

// Check for saved theme preference or default to light mode
const currentTheme = localStorage.getItem('theme') || 'light';

// Apply saved theme on page load
if (currentTheme === 'dark') {
    body.classList.add('dark-mode');
}

// Toggle dark mode
themeToggle.addEventListener('click', () => {
    body.classList.toggle('dark-mode');

    // Save theme preference
    const theme = body.classList.contains('dark-mode') ? 'dark' : 'light';
    localStorage.setItem('theme', theme);
});

// ========================================
// Active Navigation Link on Scroll
// ========================================

function setActiveNavLink() {
    const sections = document.querySelectorAll('.section');
    const scrollPosition = window.scrollY + 100;

    sections.forEach(section => {
        const sectionTop = section.offsetTop;
        const sectionHeight = section.offsetHeight;
        const sectionId = section.getAttribute('id');

        if (scrollPosition >= sectionTop && scrollPosition < sectionTop + sectionHeight) {
            navLinks.forEach(link => {
                link.classList.remove('active');
                if (link.getAttribute('href') === `#${sectionId}`) {
                    link.classList.add('active');
                }
            });
        }
    });
}

window.addEventListener('scroll', setActiveNavLink);

// ========================================
// Navbar Background on Scroll
// ========================================

const navbar = document.getElementById('navbar');

window.addEventListener('scroll', () => {
    const isDarkMode = body.classList.contains('dark-mode');

    if (window.scrollY > 50) {
        if (isDarkMode) {
            navbar.style.background = 'rgba(17, 24, 39, 0.98)';
        } else {
            navbar.style.background = 'rgba(255, 255, 255, 0.98)';
        }
        navbar.style.boxShadow = '0 4px 6px -1px rgba(0, 0, 0, 0.15)';
    } else {
        if (isDarkMode) {
            navbar.style.background = 'rgba(17, 24, 39, 0.95)';
        } else {
            navbar.style.background = 'rgba(255, 255, 255, 0.95)';
        }
        navbar.style.boxShadow = '0 4px 6px -1px rgba(0, 0, 0, 0.1)';
    }
});

// ========================================
// Smooth Scroll for Navigation Links
// ========================================

navLinks.forEach(link => {
    link.addEventListener('click', (e) => {
        e.preventDefault();
        const targetId = link.getAttribute('href');
        const targetSection = document.querySelector(targetId);

        if (targetSection) {
            const offsetTop = targetSection.offsetTop - 70;
            window.scrollTo({
                top: offsetTop,
                behavior: 'smooth'
            });
        }
    });
});

// ========================================
// Contact Form Submission
// ========================================

const contactForm = document.getElementById('contactForm');

contactForm.addEventListener('submit', (e) => {
    e.preventDefault();

    // Get form values
    const formData = new FormData(contactForm);

    // Display success message (you can integrate with a backend here)
    alert('Thank you for your message! We will get back to you soon.');

    // Reset form
    contactForm.reset();
});

// ========================================
// Scroll Animations
// ========================================

function revealOnScroll() {
    const elements = document.querySelectorAll('.video-card, .download-card, .tech-item, .info-item');

    elements.forEach(element => {
        const elementTop = element.getBoundingClientRect().top;
        const windowHeight = window.innerHeight;

        if (elementTop < windowHeight - 100) {
            element.style.opacity = '1';
            element.style.transform = 'translateY(0)';
        }
    });
}

// Initialize elements for animation
document.addEventListener('DOMContentLoaded', () => {
    const elements = document.querySelectorAll('.video-card, .download-card, .tech-item, .info-item');
    elements.forEach(element => {
        element.style.opacity = '0';
        element.style.transform = 'translateY(30px)';
        element.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
    });
});

window.addEventListener('scroll', revealOnScroll);
window.addEventListener('load', revealOnScroll);

// ========================================
// Download Button Click Handler
// ========================================

const downloadButtons = document.querySelectorAll('.download-button');

downloadButtons.forEach(button => {
    button.addEventListener('click', (e) => {
        e.preventDefault();

        // Get the parent card's title
        const card = button.closest('.download-card');
        const title = card.querySelector('h3').textContent;

        // Display message (replace with actual download logic)
        alert(`Downloading: ${title}\n\nNote: Please add your actual download links to the HTML.`);
    });
});

// ========================================
// Parallax Effect for Hero Section
// ========================================

window.addEventListener('scroll', () => {
    const hero = document.querySelector('.hero-content');
    const scrolled = window.pageYOffset;

    if (hero) {
        hero.style.transform = `translateY(${scrolled * 0.5}px)`;
        hero.style.opacity = 1 - scrolled / 700;
    }
});

// ========================================
// Console Welcome Message
// ========================================

console.log('%c Welcome to IT Consulting & Training ', 'background: linear-gradient(135deg, #393185 0%, #25b9ce 100%); color: white; font-size: 20px; padding: 10px;');
console.log('%c We specialize in Cloud, Security, Networking & Programming ', 'color: #393185; font-size: 14px;');

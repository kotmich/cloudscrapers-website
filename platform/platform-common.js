// Common Platform JavaScript
// Dark Mode and Language Switcher functionality for all platform pages

(function() {
    'use strict';

    // ========================================
    // Dark Mode
    // ========================================

    const themeToggle = document.getElementById('themeToggle');
    const body = document.body;

    // Initialize theme
    const currentTheme = localStorage.getItem('theme') || 'light';
    if (currentTheme === 'dark') {
        body.classList.add('dark-mode');
    }

    // Toggle dark mode
    if (themeToggle) {
        themeToggle.addEventListener('click', () => {
            body.classList.toggle('dark-mode');
            const theme = body.classList.contains('dark-mode') ? 'dark' : 'light';
            localStorage.setItem('theme', theme);
        });
    }

    // ========================================
    // Language Switcher
    // ========================================

    const languageToggle = document.getElementById('languageToggle');
    let currentLanguage = localStorage.getItem('language') || 'en';

    // Function to get nested translation value
    function getNestedTranslation(obj, path) {
        return path.split('.').reduce((current, key) => current?.[key], obj);
    }

    // Function to update page content based on language
    function updateLanguage(lang) {
        currentLanguage = lang;
        localStorage.setItem('language', lang);
        document.documentElement.lang = lang;

        // Update language button
        if (languageToggle) {
            const langFlag = languageToggle.querySelector('.lang-flag');
            const langText = languageToggle.querySelector('.lang-text');

            if (lang === 'en') {
                langFlag.textContent = '🇬🇧';
                langText.textContent = 'EN';
            } else {
                langFlag.textContent = '🇵🇱';
                langText.textContent = 'PL';
            }
        }

        // Update all elements with data-i18n attribute
        document.querySelectorAll('[data-i18n]').forEach(element => {
            const key = element.getAttribute('data-i18n');
            const translation = getNestedTranslation(platformTranslations[lang], key);

            if (translation) {
                if (element.hasAttribute('placeholder')) {
                    element.setAttribute('placeholder', translation);
                } else {
                    element.textContent = translation;
                }
            }
        });
    }

    // Initialize language on page load
    updateLanguage(currentLanguage);

    // Toggle language
    if (languageToggle) {
        languageToggle.addEventListener('click', () => {
            const newLang = currentLanguage === 'en' ? 'pl' : 'en';
            updateLanguage(newLang);
        });
    }

    // Export for global use
    window.platformCommon = {
        updateLanguage: updateLanguage,
        getCurrentLanguage: () => currentLanguage
    };
})();

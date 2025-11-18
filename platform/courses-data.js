// Course Data for CloudScrapers Learning Platform

const coursesData = [
    {
        id: 1,
        title: 'Intro to Programming - C/C++',
        description: 'From basics to advanced programming concepts with C/C++, including data structures and algorithms',
        instructor: 'Michał Kot',
        duration: '15 hours',
        level: 'Beginner',
        thumbnail: '../img/course-programming.jpg',
        category: 'Programming',
        lessons: 30,
        enrolledStudents: 2100,
        rating: 4.9,
        isFree: true,
        price: 0,
        videoUrl: 'https://www.youtube.com/embed/videoseries?list=PLBcO__cmGw5aRqegAevEnIT3I7g-_E0p1',
        syllabus: [
            { title: 'C++ Fundamentals', duration: '40 min' },
            { title: 'Object-Oriented Programming', duration: '50 min' },
            { title: 'Data Structures', duration: '45 min' },
            { title: 'Algorithms', duration: '55 min' },
            { title: 'Advanced C++ Features', duration: '60 min' }
        ]
    },
    {
        id: 2,
        title: 'Cybersecurity Essentials',
        description: 'Comprehensive introduction to cybersecurity, covering threat analysis, risk management, and compliance',
        instructor: 'Michał Kot',
        duration: '11 hours',
        level: 'Beginner',
        thumbnail: '../img/course-cybersecurity.jpg',
        category: 'Security',
        lessons: 22,
        enrolledStudents: 1450,
        rating: 4.7,
        isFree: false,
        price: 279,
        videoUrl: 'https://www.youtube.com/embed/videoseries?list=YOUR_CYBERSECURITY_PLAYLIST',
        syllabus: [
            { title: 'Introduction to Cybersecurity', duration: '30 min' },
            { title: 'Threat Landscape', duration: '40 min' },
            { title: 'Security Operations', duration: '45 min' },
            { title: 'Incident Response', duration: '50 min' },
            { title: 'Compliance and Governance', duration: '35 min' }
        ]
    },
    {
        id: 3,
        title: 'Networking Fundamentals',
        description: 'Master the fundamentals of computer networking, including protocols, network architecture, and troubleshooting',
        instructor: 'Michał Kot',
        duration: '12 hours',
        level: 'Beginner',
        thumbnail: '../img/course-networking.jpg',
        category: 'Networking',
        lessons: 24,
        enrolledStudents: 1850,
        rating: 4.8,
        isFree: false,
        price: 249,
        videoUrl: 'https://www.youtube.com/embed/videoseries?list=YOUR_NETWORKING_PLAYLIST',
        syllabus: [
            { title: 'Introduction to Networking', duration: '35 min' },
            { title: 'TCP/IP Protocol Suite', duration: '45 min' },
            { title: 'Network Devices and Topologies', duration: '40 min' },
            { title: 'Routing and Switching Basics', duration: '50 min' },
            { title: 'Network Troubleshooting', duration: '45 min' }
        ]
    }
];

// Helper function to get course by ID
function getCourseById(courseId) {
    return coursesData.find(course => course.id === parseInt(courseId));
}

// Helper function to filter courses by category
function getCoursesByCategory(category) {
    return coursesData.filter(course => course.category === category);
}

// Helper function to get all categories
function getAllCategories() {
    return [...new Set(coursesData.map(course => course.category))];
}

// Helper function to get free courses
function getFreeCourses() {
    return coursesData.filter(course => course.isFree);
}

// Helper function to get paid courses
function getPaidCourses() {
    return coursesData.filter(course => !course.isFree);
}

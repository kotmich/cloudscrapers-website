// Course Data for CloudScrapers Learning Platform

const coursesData = [
    {
        id: 1,
        title: 'Cloud Architecture Masterclass',
        description: 'Learn cloud infrastructure design and deployment strategies with AWS, Azure, and GCP',
        instructor: 'Michał Kot',
        duration: '12 hours',
        level: 'Intermediate',
        thumbnail: '../img/course-cloud.jpg',
        category: 'Cloud Computing',
        lessons: 24,
        enrolledStudents: 1250,
        rating: 4.8,
        isFree: false,
        price: 299,
        videoUrl: 'https://www.youtube.com/embed/videoseries?list=PLBcO__cmGw5aUCZYOcbI1wkMURl9Gb_nK',
        syllabus: [
            { title: 'Introduction to Cloud Computing', duration: '30 min' },
            { title: 'AWS Fundamentals', duration: '45 min' },
            { title: 'Azure Services Overview', duration: '45 min' },
            { title: 'GCP Architecture', duration: '40 min' },
            { title: 'Multi-Cloud Strategy', duration: '35 min' }
        ]
    },
    {
        id: 2,
        title: 'Network Security Fundamentals',
        description: 'Master network security protocols, firewalls, VPNs, and best practices for securing enterprise networks',
        instructor: 'Michał Kot',
        duration: '10 hours',
        level: 'Beginner',
        thumbnail: '../img/course-security.jpg',
        category: 'Security',
        lessons: 20,
        enrolledStudents: 980,
        rating: 4.7,
        isFree: false,
        price: 249,
        videoUrl: 'https://www.youtube.com/embed/videoseries?list=PLBcO__cmGw5bId6tysCmYZDqYDWg52HEl',
        syllabus: [
            { title: 'Network Security Basics', duration: '25 min' },
            { title: 'Firewall Configuration', duration: '40 min' },
            { title: 'VPN Setup and Management', duration: '35 min' },
            { title: 'Intrusion Detection Systems', duration: '45 min' },
            { title: 'Security Best Practices', duration: '30 min' }
        ]
    },
    {
        id: 3,
        title: 'Programming Essentials - C/C++',
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
        id: 4,
        title: 'Network Automation with Python',
        description: 'Automate your network management tasks using Python scripts and modern automation frameworks',
        instructor: 'Michał Kot',
        duration: '8 hours',
        level: 'Intermediate',
        thumbnail: '../img/course-automation.jpg',
        category: 'Networking',
        lessons: 16,
        enrolledStudents: 750,
        rating: 4.6,
        isFree: true,
        price: 0,
        videoUrl: 'https://www.youtube.com/embed/videoseries?list=PLBcO__cmGw5auu4XI4rYrrSVapXq81CGA',
        syllabus: [
            { title: 'Python for Network Engineers', duration: '35 min' },
            { title: 'Netmiko and Paramiko', duration: '40 min' },
            { title: 'NAPALM Framework', duration: '45 min' },
            { title: 'Ansible for Networks', duration: '50 min' },
            { title: 'Real-World Automation Projects', duration: '55 min' }
        ]
    },
    {
        id: 5,
        title: 'Kubernetes Deep Dive',
        description: 'Master container orchestration with Kubernetes, from basic concepts to advanced deployment strategies',
        instructor: 'Michał Kot',
        duration: '14 hours',
        level: 'Advanced',
        thumbnail: '../img/course-kubernetes.jpg',
        category: 'Cloud Computing',
        lessons: 28,
        enrolledStudents: 890,
        rating: 4.8,
        isFree: false,
        price: 349,
        videoUrl: 'https://www.youtube.com/embed/videoseries?list=YOUR_KUBERNETES_PLAYLIST',
        syllabus: [
            { title: 'Kubernetes Architecture', duration: '45 min' },
            { title: 'Pods and Deployments', duration: '50 min' },
            { title: 'Services and Networking', duration: '55 min' },
            { title: 'Storage and StatefulSets', duration: '60 min' },
            { title: 'Production Best Practices', duration: '65 min' }
        ]
    },
    {
        id: 6,
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

// Authentication System for CloudScrapers Learning Platform
// Uses localStorage for demo purposes

class AuthSystem {
    constructor() {
        this.initializeDummyUsers();
    }

    // Initialize system with dummy users
    initializeDummyUsers() {
        const users = this.getUsers();
        if (users.length === 0) {
            // Create a dummy user for testing
            const dummyUser = {
                id: 1,
                email: 'demo@cloudscrapers.pl',
                password: 'demo123', // In production, this would be hashed
                firstName: 'Demo',
                lastName: 'User',
                registeredDate: new Date().toISOString(),
                enrolledCourses: [1, 2] // Enrolled in first two courses
            };
            this.saveUser(dummyUser);
        }
    }

    // Get all users from localStorage
    getUsers() {
        const usersJson = localStorage.getItem('cloudscrapers_users');
        return usersJson ? JSON.parse(usersJson) : [];
    }

    // Save a new user
    saveUser(user) {
        const users = this.getUsers();
        users.push(user);
        localStorage.setItem('cloudscrapers_users', JSON.stringify(users));
    }

    // Update existing user
    updateUser(userId, updates) {
        const users = this.getUsers();
        const index = users.findIndex(u => u.id === userId);
        if (index !== -1) {
            users[index] = { ...users[index], ...updates };
            localStorage.setItem('cloudscrapers_users', JSON.stringify(users));
            return users[index];
        }
        return null;
    }

    // Register a new user
    register(email, password, firstName, lastName) {
        const users = this.getUsers();

        // Check if user already exists
        if (users.find(u => u.email === email)) {
            return { success: false, message: 'User with this email already exists' };
        }

        const newUser = {
            id: users.length + 1,
            email,
            password, // In production, hash this!
            firstName,
            lastName,
            registeredDate: new Date().toISOString(),
            enrolledCourses: []
        };

        this.saveUser(newUser);
        return { success: true, message: 'Registration successful', user: newUser };
    }

    // Login user
    login(email, password) {
        const users = this.getUsers();
        const user = users.find(u => u.email === email && u.password === password);

        if (user) {
            // Create session
            const session = {
                userId: user.id,
                email: user.email,
                firstName: user.firstName,
                lastName: user.lastName,
                loginTime: new Date().toISOString()
            };
            localStorage.setItem('cloudscrapers_session', JSON.stringify(session));
            return { success: true, message: 'Login successful', user: session };
        }

        return { success: false, message: 'Invalid email or password' };
    }

    // Logout user
    logout() {
        localStorage.removeItem('cloudscrapers_session');
    }

    // Check if user is logged in
    isLoggedIn() {
        const session = localStorage.getItem('cloudscrapers_session');
        return session !== null;
    }

    // Get current user session
    getCurrentUser() {
        const sessionJson = localStorage.getItem('cloudscrapers_session');
        return sessionJson ? JSON.parse(sessionJson) : null;
    }

    // Get full user data
    getUserData(userId) {
        const users = this.getUsers();
        return users.find(u => u.id === userId);
    }

    // Enroll user in course
    enrollCourse(userId, courseId) {
        const userData = this.getUserData(userId);
        if (userData && !userData.enrolledCourses.includes(courseId)) {
            userData.enrolledCourses.push(courseId);
            this.updateUser(userId, { enrolledCourses: userData.enrolledCourses });
            return true;
        }
        return false;
    }

    // Check if user is enrolled in course
    isEnrolled(userId, courseId) {
        const userData = this.getUserData(userId);
        return userData && userData.enrolledCourses.includes(courseId);
    }
}

// Create global auth instance
const auth = new AuthSystem();

/**
 * Portfolio JavaScript
 * Animated network background + UI interactions
 * Juan - 42 Madrid
 */

// =====================================================
// NETWORK CANVAS ANIMATION
// =====================================================

class NetworkCanvas {
    constructor() {
        this.canvas = document.getElementById('matrix-canvas');
        this.ctx = this.canvas.getContext('2d');
        this.particles = [];
        this.mouse = { x: null, y: null, radius: 150 };
        this.particleCount = 80;
        this.connectionDistance = 120;
        this.particleColor = '#00babc';
        this.lineColor = 'rgba(0, 186, 188, 0.15)';
        
        this.init();
        this.animate();
        this.setupEventListeners();
    }
    
    init() {
        this.resize();
        this.createParticles();
    }
    
    resize() {
        this.canvas.width = window.innerWidth;
        this.canvas.height = window.innerHeight;
    }
    
    createParticles() {
        this.particles = [];
        const area = this.canvas.width * this.canvas.height;
        this.particleCount = Math.floor(area / 15000);
        
        for (let i = 0; i < this.particleCount; i++) {
            this.particles.push({
                x: Math.random() * this.canvas.width,
                y: Math.random() * this.canvas.height,
                vx: (Math.random() - 0.5) * 0.5,
                vy: (Math.random() - 0.5) * 0.5,
                radius: Math.random() * 2 + 1,
                baseRadius: Math.random() * 2 + 1,
                angle: Math.random() * Math.PI * 2,
                angleSpeed: (Math.random() - 0.5) * 0.02
            });
        }
    }
    
    setupEventListeners() {
        window.addEventListener('resize', () => {
            this.resize();
            this.createParticles();
        });
        
        window.addEventListener('mousemove', (e) => {
            this.mouse.x = e.clientX;
            this.mouse.y = e.clientY;
        });
        
        window.addEventListener('mouseout', () => {
            this.mouse.x = null;
            this.mouse.y = null;
        });
    }
    
    drawParticle(particle) {
        this.ctx.beginPath();
        this.ctx.arc(particle.x, particle.y, particle.radius, 0, Math.PI * 2);
        this.ctx.fillStyle = this.particleColor;
        this.ctx.fill();
    }
    
    drawConnections() {
        for (let i = 0; i < this.particles.length; i++) {
            for (let j = i + 1; j < this.particles.length; j++) {
                const dx = this.particles[i].x - this.particles[j].x;
                const dy = this.particles[i].y - this.particles[j].y;
                const distance = Math.sqrt(dx * dx + dy * dy);
                
                if (distance < this.connectionDistance) {
                    const opacity = (1 - distance / this.connectionDistance) * 0.5;
                    this.ctx.beginPath();
                    this.ctx.strokeStyle = `rgba(0, 186, 188, ${opacity})`;
                    this.ctx.lineWidth = 0.5;
                    this.ctx.moveTo(this.particles[i].x, this.particles[i].y);
                    this.ctx.lineTo(this.particles[j].x, this.particles[j].y);
                    this.ctx.stroke();
                }
            }
        }
    }
    
    updateParticle(particle) {
        // Subtle floating motion using sine waves
        particle.angle += particle.angleSpeed;
        particle.x += particle.vx + Math.sin(particle.angle) * 0.2;
        particle.y += particle.vy + Math.cos(particle.angle) * 0.2;
        
        // Mouse interaction
        if (this.mouse.x !== null && this.mouse.y !== null) {
            const dx = particle.x - this.mouse.x;
            const dy = particle.y - this.mouse.y;
            const distance = Math.sqrt(dx * dx + dy * dy);
            
            if (distance < this.mouse.radius) {
                const force = (this.mouse.radius - distance) / this.mouse.radius;
                const angle = Math.atan2(dy, dx);
                particle.x += Math.cos(angle) * force * 2;
                particle.y += Math.sin(angle) * force * 2;
                particle.radius = particle.baseRadius + force * 2;
            } else {
                particle.radius = particle.baseRadius;
            }
        }
        
        // Wrap around edges
        if (particle.x < 0) particle.x = this.canvas.width;
        if (particle.x > this.canvas.width) particle.x = 0;
        if (particle.y < 0) particle.y = this.canvas.height;
        if (particle.y > this.canvas.height) particle.y = 0;
    }
    
    animate() {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        
        // Update and draw particles
        this.particles.forEach(particle => {
            this.updateParticle(particle);
            this.drawParticle(particle);
        });
        
        // Draw connections
        this.drawConnections();
        
        requestAnimationFrame(() => this.animate());
    }
}

// =====================================================
// SMOOTH SCROLL
// =====================================================

function initSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            const targetId = this.getAttribute('href');
            const target = document.querySelector(targetId);
            
            if (target) {
                const navHeight = document.querySelector('.navbar').offsetHeight;
                const targetPosition = target.getBoundingClientRect().top + window.pageYOffset - navHeight;
                
                window.scrollTo({
                    top: targetPosition,
                    behavior: 'smooth'
                });
            }
        });
    });
}

// =====================================================
// SCROLL ANIMATIONS (Intersection Observer)
// =====================================================

function initScrollAnimations() {
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry, index) => {
            if (entry.isIntersecting) {
                // Staggered animation delay
                setTimeout(() => {
                    entry.target.classList.add('animate-in');
                }, index * 100);
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);
    
    // Observe project cards and contact cards
    document.querySelectorAll('.project-card, .contact-card').forEach(el => {
        el.classList.add('animate-hidden');
        observer.observe(el);
    });
    
    // Add animation styles
    const style = document.createElement('style');
    style.textContent = `
        .animate-hidden {
            opacity: 0;
            transform: translateY(40px);
        }
        .animate-in {
            opacity: 1 !important;
            transform: translateY(0) !important;
            transition: opacity 0.6s cubic-bezier(0.4, 0, 0.2, 1), 
                        transform 0.6s cubic-bezier(0.4, 0, 0.2, 1);
        }
    `;
    document.head.appendChild(style);
}

// =====================================================
// NAVBAR SCROLL EFFECT
// =====================================================

function initNavbarScroll() {
    const navbar = document.querySelector('.navbar');
    let lastScroll = 0;
    
    window.addEventListener('scroll', () => {
        const currentScroll = window.pageYOffset;
        
        if (currentScroll > 100) {
            navbar.style.background = 'rgba(10, 10, 15, 0.95)';
            navbar.style.boxShadow = '0 4px 30px rgba(0, 0, 0, 0.3)';
        } else {
            navbar.style.background = 'rgba(10, 10, 15, 0.8)';
            navbar.style.boxShadow = 'none';
        }
        
        lastScroll = currentScroll;
    });
}

// =====================================================
// TERMINAL TYPING ANIMATION
// =====================================================

function initTerminalAnimation() {
    const terminalBody = document.querySelector('.terminal-body');
    if (!terminalBody) return;
    
    const lines = terminalBody.querySelectorAll('p');
    
    lines.forEach((line, index) => {
        line.style.opacity = '0';
        line.style.transform = 'translateX(-10px)';
        
        setTimeout(() => {
            line.style.transition = 'opacity 0.3s ease, transform 0.3s ease';
            line.style.opacity = '1';
            line.style.transform = 'translateX(0)';
        }, 500 + index * 200);
    });
}

// =====================================================
// ACTIVE NAV LINK HIGHLIGHT
// =====================================================

function initActiveNavHighlight() {
    const sections = document.querySelectorAll('section[id]');
    const navLinks = document.querySelectorAll('.nav-links a');
    
    window.addEventListener('scroll', () => {
        let current = '';
        const navHeight = document.querySelector('.navbar').offsetHeight;
        
        sections.forEach(section => {
            const sectionTop = section.offsetTop - navHeight - 100;
            const sectionHeight = section.offsetHeight;
            
            if (window.pageYOffset >= sectionTop && 
                window.pageYOffset < sectionTop + sectionHeight) {
                current = section.getAttribute('id');
            }
        });
        
        navLinks.forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href') === `#${current}`) {
                link.classList.add('active');
            }
        });
    });
    
    // Add active style
    const style = document.createElement('style');
    style.textContent = `
        .nav-links a.active {
            color: #00babc;
        }
        .nav-links a.active::after {
            width: 100%;
        }
    `;
    document.head.appendChild(style);
}

// =====================================================
// EASTER EGG - Console Art
// =====================================================

function showConsoleEasterEgg() {
    const asciiArt = `
%c
     ██╗██╗   ██╗ █████╗ ███╗   ██╗
     ██║██║   ██║██╔══██╗████╗  ██║
     ██║██║   ██║███████║██╔██╗ ██║
██   ██║██║   ██║██╔══██║██║╚██╗██║
╚█████╔╝╚██████╔╝██║  ██║██║ ╚████║
 ╚════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝

`;
    console.log(asciiArt, 'color: #00babc; font-family: monospace;');
    console.log('%c Software Engineer | 42 Madrid ', 
        'background: linear-gradient(90deg, #00babc, #0ea5e9); color: #0a0a0f; padding: 8px 16px; border-radius: 4px; font-weight: bold;');
    console.log('%c Inception Services Running:', 'color: #94a3b8; font-size: 12px;');
    console.log('%c   NGINX    %c TLS 1.3', 'color: #27ca3f;', 'color: #64748b;');
    console.log('%c   WordPress %c PHP-FPM 8.2', 'color: #27ca3f;', 'color: #64748b;');
    console.log('%c   MariaDB  %c InnoDB', 'color: #27ca3f;', 'color: #64748b;');
    console.log('%c   Redis    %c Cache Layer', 'color: #27ca3f;', 'color: #64748b;');
    console.log('%c   Static   %c This Site', 'color: #27ca3f;', 'color: #64748b;');
}

// =====================================================
// INIT
// =====================================================

document.addEventListener('DOMContentLoaded', () => {
    // Initialize all modules
    new NetworkCanvas();
    initSmoothScroll();
    initScrollAnimations();
    initNavbarScroll();
    initTerminalAnimation();
    initActiveNavHighlight();
    showConsoleEasterEgg();
});

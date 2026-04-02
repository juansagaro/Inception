/**
 * Portfolio JavaScript
 * Sitio estático para el proyecto Inception de 42
 */

document.addEventListener('DOMContentLoaded', function() {
    // Smooth scroll para los enlaces de navegación
    initSmoothScroll();
    
    // Animaciones al hacer scroll
    initScrollAnimations();
    
    // Efecto de typing en el hero
    initTypingEffect();
});

/**
 * Smooth scroll para navegación interna
 */
function initSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
}

/**
 * Animaciones al entrar elementos en viewport
 */
function initScrollAnimations() {
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);

    // Observar cards
    document.querySelectorAll('.skill-card, .project-card, .contact-link').forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });

    // Añadir estilos para la clase visible
    const style = document.createElement('style');
    style.textContent = `
        .skill-card.visible, .project-card.visible, .contact-link.visible {
            opacity: 1 !important;
            transform: translateY(0) !important;
        }
    `;
    document.head.appendChild(style);
}

/**
 * Efecto de typing en el subtítulo
 */
function initTypingEffect() {
    const subtitle = document.querySelector('.subtitle');
    if (!subtitle) return;

    const text = subtitle.textContent;
    subtitle.textContent = '';
    subtitle.style.borderRight = '2px solid var(--primary-color)';
    
    let index = 0;
    const typeInterval = setInterval(() => {
        if (index < text.length) {
            subtitle.textContent += text.charAt(index);
            index++;
        } else {
            clearInterval(typeInterval);
            // Parpadeo del cursor
            setInterval(() => {
                subtitle.style.borderRight = subtitle.style.borderRight === 'none' 
                    ? '2px solid var(--primary-color)' 
                    : 'none';
            }, 500);
        }
    }, 50);
}

/**
 * Mostrar info del proyecto Inception
 */
function showInceptionInfo() {
    console.log('%c Inception 42 ', 
        'background: #00babc; color: #1a1a2e; font-size: 20px; padding: 10px;');
    console.log('Servicios corriendo:');
    console.log('  - NGINX (TLS 1.2/1.3)');
    console.log('  - WordPress + PHP-FPM');
    console.log('  - MariaDB');
    console.log('  - Redis Cache');
    console.log('  - Adminer');
    console.log('  - Static Site (este)');
    console.log('  - Portainer');
    console.log('  - FTP Server');
}

// Easter egg en consola
showInceptionInfo();

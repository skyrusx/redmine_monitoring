document.addEventListener('DOMContentLoaded', function () {
    // помечаем каждый <tbody> как отдельный уровень аккордеона
    document.querySelectorAll('table tbody').forEach(tb => tb.setAttribute('data-accordion-scope', ''));

    const INTERACTIVE =
        'a, button, [role="button"], input, textarea, select, .mm-copy-btn, .select2, .select2-container';

    function isInteractiveClick(e) {
        return !!e.target.closest(INTERACTIVE);
    }

    function levelScope(el) {
        return el.closest('[data-accordion-scope]') || el.closest('table') || document;
    }

    function findDetails(trigger) {
        // 1) если задан data-target — ищем внутри scope, а не глобально
        const id = trigger.getAttribute('data-target');
        if (id) {
            const scope = levelScope(trigger);
            const byId = scope.querySelector('#' + CSS.escape(id));
            if (byId && byId.classList.contains('details-row')) return byId;
        }
        // 2) fallback — соседняя строка .details-row
        let next = trigger.nextElementSibling;
        while (next && !(next.classList && next.classList.contains('details-row'))) {
            next = next.nextElementSibling;
        }
        return next || null;
    }

    function closeSiblings(scopeEl, exceptDetails) {
        scopeEl.querySelectorAll('.error-row').forEach(row => row.classList.remove('active'));
        scopeEl.querySelectorAll('.details-row').forEach(row => {
            if (row !== exceptDetails) row.style.display = 'none';
        });
    }

    // --- Делегирование кликов по строкам-триггерам
    document.addEventListener('click', function (e) {
        const trigger = e.target.closest('.error-row');
        if (!trigger) return;
        if (isInteractiveClick(e)) return;

        const details = findDetails(trigger);
        if (!details) return;

        const scope = levelScope(trigger);
        const isOpen = getComputedStyle(details).display !== 'none';

        if (isOpen) {
            details.style.display = 'none';
            trigger.classList.remove('active');
        } else {
            closeSiblings(scope, details);
            details.style.display = 'table-row';
            trigger.classList.add('active');
        }
    });

    // --- Делегирование для кнопок копирования
    document.addEventListener('click', function (e) {
        const btn = e.target.closest('.mm-copy-btn');
        if (!btn) return;
        e.stopPropagation();

        const targetId = btn.getAttribute('data-target');
        const scope = btn.closest('[data-accordion-scope]') || btn.closest('table') || document;
        const codeBlock = targetId && scope.querySelector('#' + CSS.escape(targetId));
        if (!codeBlock) return;

        navigator.clipboard.writeText(codeBlock.innerText).then(function () {
            const old = btn.innerHTML;
            btn.innerHTML =
                '<svg viewBox="0 0 24 24"><path d="M16 1H6a2 2 0 0 0-2 2v12h2V3h10V1zm3 4H10a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h9a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2zm0 16H10V7h9v14z"/></svg>Скопировано';
            setTimeout(function () {
                btn.innerHTML = old;
            }, 1200);
        });
    });

    if (window.$) {
        $('.monitoring-select2').select2({
            width: '100%',
            allowClear: true,
            placeholder: function () {
                return $(this).data('placeholder') || 'Выберите...';
            }
        });
    }

    // --- Preloader
    (function () {
        var overlay = document.getElementById('mm-preloader');

        function showPreloader() {
            if (!overlay) return;
            overlay.style.display = 'flex';
            overlay.setAttribute('aria-hidden', 'false');
        }

        document.addEventListener('click', function (e) {
            var a = e.target.closest && e.target.closest('a.js-preloader');
            if (!a) return;

            // только «обычный» клик в эту вкладку
            if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
            if (a.target && a.target !== '_self') return;

            // блокируем повторные клики/даблклик
            a.classList.add('is-busy');
            a.style.pointerEvents = 'none';
            a.setAttribute('aria-busy', 'true');

            showPreloader();
            // дальше браузер перейдёт по ссылке, прелоадер останется до загрузки новой страницы
        }, {capture: true});
    })();
});

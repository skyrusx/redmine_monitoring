document.addEventListener("DOMContentLoaded", function() {
    // раскрытие строк
    document.querySelectorAll(".error-row").forEach(function(row) {
        row.addEventListener("click", function() {
            var targetId = row.getAttribute("data-target");
            var detailsRow = document.getElementById(targetId);
            var open = detailsRow.style.display === "table-row";
            document.querySelectorAll(".details-row").forEach(r => r.style.display = "none");
            document.querySelectorAll(".error-row").forEach(r => r.classList.remove("active"));
            if (!open) {
                detailsRow.style.display = "table-row";
                row.classList.add("active");
            }
        });
    });

    // копирование
    document.querySelectorAll(".mm-copy-btn").forEach(function(btn) {
        btn.addEventListener("click", function(e) {
            e.stopPropagation();
            var targetId = btn.getAttribute("data-target");
            var codeBlock = document.getElementById(targetId);
            if (!codeBlock) return;
            navigator.clipboard.writeText(codeBlock.innerText).then(function() {
                var old = btn.innerHTML;
                btn.innerHTML = '<svg viewBox="0 0 24 24"><path d="M16 1H6a2 2 0 0 0-2 2v12h2V3h10V1zm3 4H10a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h9a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2zm0 16H10V7h9v14z"/></svg>Скопировано';
                setTimeout(function(){ btn.innerHTML = old; }, 1200);
            });
        });
    });
});

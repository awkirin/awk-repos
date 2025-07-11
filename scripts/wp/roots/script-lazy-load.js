if ('Ленивая загрузка скриптов') {
  if (!'v1 uikit') {
    document.querySelectorAll('[data-app-lazy-script]').forEach((script) => {
      let parent = script.parentElement;
      let component = UIkit.scrollspy(parent, {
        hidden: false
      });
      UIkit.util.on(parent, 'inview', function () {
        script.src = script.dataset.appLazyScript;
        component.$destroy();
      });
    });
  }
  if (!'v2 old browsers support') {
    document.querySelectorAll('[data-app-lazy-script]').forEach((script) => {
      const parent = script.parentElement;

      function loadScriptWhenVisible() {
        const rect = parent.getBoundingClientRect();
        const isVisible = (
          rect.top >= 0 &&
          rect.left >= 0 &&
          rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
          rect.right <= (window.innerWidth || document.documentElement.clientWidth)
        );

        if (isVisible) {
          script.src = script.dataset.appLazyScript;
          window.removeEventListener('scroll', loadScriptWhenVisible);
          window.removeEventListener('resize', loadScriptWhenVisible);
        }
      }

      // Проверяем сразу при загрузке
      loadScriptWhenVisible();

      // И добавляем обработчики для скролла и ресайза
      window.addEventListener('scroll', loadScriptWhenVisible);
      window.addEventListener('resize', loadScriptWhenVisible);
    });
  }
  if ('v3 native future') {
    document.querySelectorAll('[data-app-lazy-script]').forEach((script) => {
      const parent = script.parentElement;

      // Создаем Intersection Observer для отслеживания появления элемента в viewport
      const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            // Когда элемент появляется в viewport, загружаем скрипт
            script.src = script.dataset.appLazyScript;

            // Отключаем observer после загрузки
            observer.disconnect();
          }
        });
      }, {
        // Настройки observer (аналогично hidden: false в UIkit)
        threshold: 0
      });

      // Начинаем наблюдение за родительским элементом
      observer.observe(parent);
    });
  }
}

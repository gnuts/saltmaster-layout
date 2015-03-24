include:
  {% for formula in pillar.formulas %}
  - {{formula}}
  {% endfor%}

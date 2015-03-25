include:
  {%- for formula in pillar.get('formulas',[]) %}
  - {{formula}}
  {% endfor%}

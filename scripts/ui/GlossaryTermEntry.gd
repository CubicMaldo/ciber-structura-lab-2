extends Button
## GlossaryTermEntry - Entrada en la lista de términos del glosario

var term_id: String = ""
var term_name: String = ""
var term_category: String = ""
var term_complexity: String = ""

@onready var name_label: Label = $HBoxContainer/NameLabel
@onready var category_label: Label = $HBoxContainer/CategoryLabel
@onready var complexity_badge: Label = $HBoxContainer/ComplexityBadge

func setup(term) -> void:
	term_id = term.id
	term_name = term.name
	term_category = term.category
	term_complexity = term.complexity
	
	if name_label:
		name_label.text = term_name
	
	if category_label:
		category_label.text = term_category
	
	if complexity_badge:
		complexity_badge.text = term_complexity
		match term_complexity:
			"Básico":
				complexity_badge.modulate = Color(0.4, 0.85, 0.5)
			"Intermedio":
				complexity_badge.modulate = Color(1.0, 0.8, 0.2)
			"Avanzado":
				complexity_badge.modulate = Color(0.85, 0.3, 0.3)

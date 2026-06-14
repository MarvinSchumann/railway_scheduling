import clingo

ctl = clingo.Control()
ctl.load("encoding_connect.lp")
ctl.load("tracks.lp")
ctl.load("first_environment.lp")

ctl.ground([("base", [])])

optimal_model = None

with ctl.solve(yield_=True) as handle:
    for model in handle:
        optimal_model = model.symbols(shown=True)  # keeps overwriting, last = optimal

if optimal_model:
    on_atoms = sorted(
        [a for a in optimal_model if a.name == "on"],
        key=lambda a: a.arguments[3].number
    )
    for atom in on_atoms:
        t = atom.arguments[0].number
        x = atom.arguments[1].number
        y = atom.arguments[2].number
        time = atom.arguments[3].number
        orient = atom.arguments[4].name
        print(f"Train {t} at ({x},{y}) t={time} facing {orient}")
else:
    print("No optimal solution found")
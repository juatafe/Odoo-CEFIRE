from .directiva import ClasseDiagramDirective

def setup(app):
    app.add_directive("classe_diagrama", ClasseDiagramDirective)
    return {"version": "0.1"}

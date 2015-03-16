from flask import Flask, render_template, request
import os
import tempfile
import subprocess
app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello PPTK!"

@app.route('/hex', methods=['POST', 'GET'])
def get_hex():
    return(render_hexes(request.args.get('lon'), request.args.get('lat'), request.args.get('res', 10)))

def render_hexes(lon, lat, res):
    with tempfile.NamedTemporaryFile() as grid_file, \
         tempfile.NamedTemporaryFile() as bound_file:
        g = render_template('grid_gen.meta', region_bound=bound_file.name, output_file=grid_file.name)
        #g = render_template('grid_gen.meta', region_bound=bound_file.name, output_file=grid_file.name, resolution=res)
        grid_file.write(g)
        b = render_template('region_bound.gen', lon=float(lon), lat=float(lat))
        bound_file.write(b)
        grid_file.flush()
        bound_file.flush()
        subprocess.call(['./dggrid', grid_file.name])
        with open(grid_file.name+'.geojson', 'rb') as out_file:
            json = out_file.read()
        out_file.close()
        os.remove(out_file.name)
        return json

if __name__ == "__main__":
    app.run(host='0.0.0.0', debug=False)


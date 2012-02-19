all:
	coffee -o lib/ -bc src/
clean:
	rm -rf lib/
watch:
	coffee -o lib/ -wbc src/
test: all
	vows lib/test/drip-server.js

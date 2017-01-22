build: build/Release/ec.app

install: build/Release/ec.app
    rm -rf /Applications/ec.app
    mv $prereq /Applications/  

clean:    
    rm -rf build/

build/Release/ec.app:
    xcodebuild -project ec.xcodeproj -target ec -configuration Release build
    

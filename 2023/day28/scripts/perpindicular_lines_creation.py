# -*- coding: utf-8 -*-

"""
***************************************************************************
*                                                                         *
*   This program is free software; you can redistribute it and/or modify  *
*   it under the terms of the GNU General Public License as published by  *
*   the Free Software Foundation; either version 2 of the License, or     *
*   (at your option) any later version.                                   *
*                                                                         *
***************************************************************************
"""

from PyQt5.QtCore import QCoreApplication
from qgis.core import (QgsPoint,
                       QgsFeature,
                       QgsGeometry,
                       QgsProcessing,
                       QgsFeatureSink,
                       QgsProcessingException,
                       QgsProcessingAlgorithm,
                       QgsProcessingParameterDistance,
                       QgsProcessingParameterFeatureSource,
                       QgsProcessingParameterFeatureSink)
from qgis import processing
import math

class CreatePerpendicularLines(QgsProcessingAlgorithm):
    """
    Processing tool takes a vector layer and for each feature
    creates a perpindicular set of straight lines.
    
    Tool options allow defining the:
    a) interval between lines
    b) length of lines
    
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    INPUT = 'INPUT'
    OUTPUT = 'OUTPUT'
    PERP_LINE_INTERVAL = 'perp_line_interval'
    PERP_LINE_LENGTH = 'perp_line_length'

    def tr(self, string):
        """
        Returns a translatable string with the self.tr() function.
        """
        return QCoreApplication.translate('Processing', string)

    def createInstance(self):
        return CreatePerpendicularLines()

    def name(self):
        """
        Returns the algorithm name, used for identifying the algorithm. This
        string should be fixed for the algorithm, and must not be localised.
        The name should be unique within each provider. Names should contain
        lowercase alphanumeric characters only and no spaces or other
        formatting characters.
        """
        return 'perpendicular_lines'

    def displayName(self):
        """
        Returns the translated algorithm name, which should be used for any
        user-visible display of the algorithm name.
        """
        return self.tr('Perpendicular Line Creator')

    def group(self):
        """
        Returns the name of the group this algorithm belongs to. This string
        should be localised.
        """
        return self.tr('CMC Scripts')

    def groupId(self):
        """
        Returns the unique ID of the group this algorithm belongs to. This
        string should be fixed for the algorithm, and must not be localised.
        The group id should be unique within each provider. Group id should
        contain lowercase alphanumeric characters only and no spaces or other
        formatting characters.
        """
        return 'cmc_scripts'

    def shortHelpString(self):
        """
        Returns a localised short helper string for the algorithm. This string
        should provide a basic description about what the algorithm does and the
        parameters and outputs associated with it..
        """
        return self.tr("This tool takes a vector layer and for each feature"
        + "creates a perpindicular set of straight lines.\n\n"
        + "Options allow customizing:\n"
        + "a) interval between lines\n"
        + "b) length of lines")

    def initAlgorithm(self, config=None):
        """
        Here we define the inputs and output of the algorithm, along
        with some other properties.
        """

        # We add the input vector features source. It can have any kind of
        # geometry.
        self.addParameter(
            QgsProcessingParameterFeatureSource(
                self.INPUT,
                self.tr('Input layer'),
                [QgsProcessing.TypeVectorAnyGeometry]
            )
        )
        
        self.addParameter(
            QgsProcessingParameterDistance(
                self.PERP_LINE_INTERVAL,
                self.tr('Interval between lines'),
                defaultValue = 100.0,
                # Make distance units match the INPUT layer units:
                parentParameterName='INPUT'
            )
        )

        self.addParameter(
            QgsProcessingParameterDistance(
                self.PERP_LINE_LENGTH,
                self.tr('Perpendicular line length'),
                defaultValue = 1000.0,
                # Make distance units match the INPUT layer units:
                parentParameterName='INPUT'
            )
        )

        # We add a feature sink in which to store our processed features (this
        # usually takes the form of a newly created vector layer when the
        # algorithm is run in QGIS).
        self.addParameter(
            QgsProcessingParameterFeatureSink(
                self.OUTPUT,
                self.tr('Output layer')
            )
        )

    def processAlgorithm(self, parameters, context, feedback):
        """
        Here is where the processing itself takes place.
        """

        # Retrieve the feature source and sink. The 'dest_id' variable is used
        # to uniquely identify the feature sink, and must be included in the
        # dictionary returned by the processAlgorithm function.
        source = self.parameterAsSource(
            parameters,
            self.INPUT,
            context)
            
        # If source was not found, throw an exception to indicate that the algorithm
        # encountered a fatal error. The exception text can be any string, but in this
        # case we use the pre-built invalidSourceError method to return a standard
        # helper text for when a source cannot be evaluated
        if source is None:
            raise QgsProcessingException(self.invalidSourceError(parameters, self.INPUT))
            
        # Retrieve tool parameters
        perp_interval = self.parameterAsDouble(
            parameters,
            self.PERP_LINE_INTERVAL,
            context)
        perp_length = self.parameterAsDouble(
            parameters,
            self.PERP_LINE_LENGTH,
            context)
        
        # Retrieve output
        (sink, dest_id) = self.parameterAsSink(
            parameters,
            self.OUTPUT,
            context,
            source.fields(),
            source.wkbType(),
            source.sourceCrs()
        )

        # If sink was not created, throw an exception to indicate that the algorithm
        # encountered a fatal error. The exception text can be any string, but in this
        # case we use the pre-built invalidSinkError method to return a standard
        # helper text for when a sink cannot be evaluated
        if sink is None:
            raise QgsProcessingException(self.invalidSinkError(parameters, self.OUTPUT))

        # Compute the number of steps to display within the progress bar and
        # get features from source
        features = source.getFeatures()
        total_length = 0
        for current, feature in enumerate(features):
            total_length += feature.geometry().length()
        
        total_processing = 100.0 / total_length if total_length > 0 else 0
  
        ################################
        # Start of algorithm
        ################################
        total_length = 0
        
        # Process each line/feature
        features = source.getFeatures()

        for current, feature in enumerate(features):
            # feature is a QgsGeometry object: https://qgis.org/api/classQgsFeature.html
            
            # Stop the algorithm if cancel button has been clicked
            if feedback.isCanceled():
                break
            
            # g is a QgsGeometry object: https://qgis.org/api/classQgsGeometry.html
            g = feature.geometry()
            
            # get the number of vertices (may not need)
            g.convertToSingleType()
            vertex_count = len(g.asPolyline())
            
            vi = 0
            path_len = g.distanceToVertex(vertex_count - 1)

            processed_dist = 0
            feature_id = 1
            
            # Process each 'point' at a certain distance along the line/feature
            while processed_dist < path_len:
                # Stop the algorithm if cancel button has been clicked
                if feedback.isCanceled():
                    break

                # Get the angle/coords of the line at the interval distances
                path_rangle = g.interpolateAngle(processed_dist)
                path_coord = g.interpolate(processed_dist).asPoint()
                
                # we want the PERPINDICULAR of the line angle (from north, clockwise)
                perp_bearing = ( path_rangle - ( math.pi / 2 ) ) % ( 2 * math.pi )
                
                #print(str(feature_id) + ": " + str(path_rangle/math.pi*180) + " -> " + str(perp_bearing/math.pi*180))
                
                # The x,y shift is mirrored on either side of line
                # Half the hypotenuse, perp-line length
                xdiff = math.sin(perp_bearing) * perp_length / 2
                ydiff = math.cos(perp_bearing) * perp_length / 2
                
                # Left
                leftp = QgsPoint(
                    path_coord.x() + xdiff,
                    path_coord.y() + ydiff)
                
                # Right
                rightp = QgsPoint(
                    path_coord.x() - xdiff,
                    path_coord.y() - ydiff)
                
                # Create new feature and populate with attributes and geometry
                new_feature = QgsFeature(source.fields())
                new_feature.setAttribute('fid', feature_id)
                new_feature.setGeometry(QgsGeometry.fromPolyline([leftp, rightp]))
                
                # increment the feature id
                feature_id += 1
                
                # add them to sink
                sink.addFeature(new_feature, QgsFeatureSink.FastInsert)
                
                # increment to next sample point
                processed_dist += perp_interval

            # Update the progress bar
            total_length += g.length()
            feedback.setProgress(int(total_length * total_processing))
  
        # Return the results of the algorithm. In this case our only result is
        # the feature sink which contains the processed features, but some
        # algorithms may return multiple feature sinks, calculated numeric
        # statistics, etc. These should all be included in the returned
        # dictionary, with keys matching the feature corresponding parameter
        # or output names.
        return {self.OUTPUT: dest_id}

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
from qgis.core import (QgsRaster,
                       QgsProcessing,
                       QgsRasterLayer,
                       QgsProcessingException,
                       QgsProcessingAlgorithm,
                       QgsProcessingParameterDistance,
                       QgsProcessingParameterRasterLayer,
                       QgsProcessingParameterFileDestination,
                       QgsProcessingParameterFeatureSource)
from qgis import processing


class ProfileExtractor(QgsProcessingAlgorithm):
    """
    This is an example algorithm that ...
    All Processing algorithms should extend the QgsProcessingAlgorithm
    class.
    """

    # Constants used to refer to parameters and outputs. They will be
    # used when calling the algorithm from another algorithm, or when
    # calling from the QGIS console.

    RASTER_INPUT = 'RASTER_INPUT'
    VECTOR_INPUT = 'VECTOR_INPUT'
    OUTPUT = 'OUTPUT'
    SAMPLE_INTERVAL = 'sample_interval'

    def tr(self, string):
        """
        Returns a translatable string with the self.tr() function.
        """
        return QCoreApplication.translate('Processing', string)

    def createInstance(self):
        return ProfileExtractor()

    def name(self):
        """
        Returns the algorithm name, used for identifying the algorithm. This
        string should be fixed for the algorithm, and must not be localised.
        The name should be unique within each provider. Names should contain
        lowercase alphanumeric characters only and no spaces or other
        formatting characters.
        """
        return 'profile_extractor'

    def displayName(self):
        """
        Returns the translated algorithm name, which should be used for any
        user-visible display of the algorithm name.
        """
        return self.tr('Raster Profile Extractor')

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
        return self.tr("Extract features from location of vector layer features")

    def initAlgorithm(self, config=None):
        """
        Here we define the inputs and output of the algorithm, along
        with some other properties.
        """
        
        # Possible types are: https://qgis.org/api/classQgsProcessingParameterType.html

        # Get the raster to extract elevation from
        self.addParameter(
            QgsProcessingParameterRasterLayer(
                self.RASTER_INPUT,
                self.tr('Input raster layer'),
                None
            )
        )
        
        # We add the input vector features source. It can have any kind of
        # geometry.
        self.addParameter(
        
            QgsProcessingParameterFeatureSource(
                self.VECTOR_INPUT,
                self.tr('Input vector layer'),
                [QgsProcessing.TypeVectorAnyGeometry]
            )
        )
        
        # interval to sample raster along geometry
        self.addParameter(
            QgsProcessingParameterDistance(
                self.SAMPLE_INTERVAL,
                self.tr('Raster sampling interval'),
                defaultValue = 5.0,
                # Make distance units match the INPUT layer units:
                parentParameterName='VECTOR_INPUT'
            )
        )

        # Save to TSV
        self.addParameter(
            QgsProcessingParameterFileDestination(
                self.OUTPUT,
                self.tr('Output file'),
                fileFilter='TSV files (*.tsv)'
            )
        )

    def processAlgorithm(self, parameters, context, feedback):
        """
        Here is where the processing itself takes place.
        """

        # Retrieve the feature source and sink. The 'dest_id' variable is used
        # to uniquely identify the feature sink, and must be included in the
        # dictionary returned by the processAlgorithm function.
        raster_source = self.parameterAsRasterLayer(
            parameters,
            self.RASTER_INPUT,
            context
        )
        vector_source = self.parameterAsSource(
            parameters,
            self.VECTOR_INPUT,
            context
        )

        # If source was not found, throw an exception to indicate that the algorithm
        # encountered a fatal error. The exception text can be any string, but in this
        # case we use the pre-built invalidSourceError method to return a standard
        # helper text for when a source cannot be evaluated
        if raster_source is None:
            raise QgsProcessingException(self.invalidSourceError(parameters, self.RASTER_INPUT))

        if vector_source is None:
            raise QgsProcessingException(self.invalidSourceError(parameters, self.VECTOR_INPUT))

        surv_interval = self.parameterAsDouble(
            parameters,
            self.SAMPLE_INTERVAL,
            context
        )

        # Write to TSV file
        save_profiles_file = self.parameterAsFileOutput(
            parameters,
            self.OUTPUT,
            context,
        )

        ############################
        # Prep
        ############################

        # Compute the number of steps to display within the progress bar and
        # get features from source 
        feature_num = vector_source.featureCount()
        processing_step = (100.0 / feature_num) if feature_num > 0 else 0
        
        ############################
        # Algorithm loop
        ############################
        features = vector_source.getFeatures()
        rsdp = raster_source.dataProvider()
        
        # file we write results to25D
        fh = open(save_profiles_file,'w')
        delim = "\t"
        nlchar = "\n"
        fh.write("fid" + delim + "dist" + delim + "x" + delim + "y" + delim + "value_s" + nlchar)
        
        for current, feature in enumerate(features):
            # Stop the algorithm if cancel button has been clicked
            if feedback.isCanceled():
                break
            
            sampling_progress = 0
            feature_geom = feature.geometry()
            feature_length = feature_geom.length()
            
            while sampling_progress < feature_length:
                if feedback.isCanceled():
                    break
                    
                sample_point = feature_geom.interpolate(sampling_progress).asPoint()
                raster_vals = rsdp.identify(sample_point, QgsRaster.IdentifyFormatValue).results()

                fh.write(str(current) + delim + str(sampling_progress) + delim + str(sample_point.x()) + delim + str(sample_point.y()) + delim + str(raster_vals) + nlchar)
                
                # increment sampling position
                sampling_progress += surv_interval

            # Update the progress bar
            feedback.setProgress(int(current * processing_step))
        
        fh.close()

        # Return the results of the algorithm. In this case our only result is
        # the feature sink which contains the processed features, but some
        # algorithms may return multiple feature sinks, calculated numeric
        # statistics, etc. These should all be included in the returned
        # dictionary, with keys matching the feature corresponding parameter
        # or output names.
        return {self.OUTPUT: save_profiles_file}

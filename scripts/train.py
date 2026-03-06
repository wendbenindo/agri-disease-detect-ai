import os
import json
import numpy as np
import tensorflow as tf
from tensorflow.keras.applications import MobileNetV2, EfficientNetB0, ResNet50V2
from tensorflow.keras.models import Model
from tensorflow.keras.layers import (
    Dense, GlobalAveragePooling2D, Dropout, 
    BatchNormalization, Input
)
from tensorflow.keras.optimizers import Adam, SGD
from tensorflow.keras.callbacks import (
    EarlyStopping, ReduceLROnPlateau, ModelCheckpoint,
    TensorBoard, CSVLogger
)
from tensorflow.keras.regularizers import l2
from tensorflow.keras.metrics import (
    Precision, Recall, TopKCategoricalAccuracy
)
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.utils.class_weight import compute_class_weight
import datetime
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

# Configuration pour la reproductibilité
tf.random.set_seed(42)
np.random.seed(42)

class PlantDiseaseTrainer:
    """
    Classe complète pour l'entraînement optimisé de modèles de détection
    de maladies de plantes avec toutes les bonnes pratiques.
    """
    
    def __init__(self, 
                 img_size=(224, 224),
                 batch_size=32,
                 base_model_name='mobilenetv2',
                 num_classes=None):
        """
        Initialise le trainer avec les paramètres optimisés
        """
        self.img_size = img_size
        self.batch_size = batch_size
        self.base_model_name = base_model_name.lower()
        self.num_classes = num_classes
        
        # Créer les répertoires nécessaires
        self.setup_directories()
        
        # Configurer TensorFlow pour les performances
        self.configure_tensorflow()
        
        # Attributs pour stocker les résultats
        self.model = None
        self.history = None
        self.class_weights = None
        self.class_indices = None
        
    def setup_directories(self):
        """
        Crée la structure de répertoires nécessaire
        """
        self.base_dir = Path(__file__).parent
        self.model_dir = self.base_dir.parent / 'model'
        self.logs_dir = self.base_dir / 'logs'
        self.results_dir = self.base_dir / 'results'
        
        # Créer les répertoires
        for dir_path in [self.model_dir, self.logs_dir, self.results_dir]:
            dir_path.mkdir(exist_ok=True)
            
        # Répertoire avec timestamp pour cette session
        self.session_dir = self.results_dir / datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
        self.session_dir.mkdir(exist_ok=True)
    
    def configure_tensorflow(self):
        """
        Configure TensorFlow pour les performances optimales
        """
        # Configuration GPU si disponible
        gpus = tf.config.experimental.list_physical_devices('GPU')
        if gpus:
            try:
                # Permettre la croissance de la mémoire GPU
                for gpu in gpus:
                    tf.config.experimental.set_memory_growth(gpu, True)
                print(f"✅ GPU configuré: {len(gpus)} GPU(s) disponible(s)")
            except RuntimeError as e:
                print(f"⚠️ Erreur configuration GPU: {e}")
        else:
            print("⚠️ Aucun GPU détecté, utilisation du CPU")
        
        # Configuration des threads pour CPU
        tf.config.threading.set_intra_op_parallelism_threads(0)
        tf.config.threading.set_inter_op_parallelism_threads(0)
    
    def create_advanced_model(self, num_classes):
        """
        Crée un modèle avancé avec architecture optimisée
        """
        print(f"🏗️ Création du modèle basé sur {self.base_model_name}...")
        
        # Sélection du modèle de base
        base_models = {
            'mobilenetv2': MobileNetV2,
            'efficientnetb0': EfficientNetB0,
            'resnet50v2': ResNet50V2
        }
        
        if self.base_model_name not in base_models:
            raise ValueError(f"Modèle de base non supporté: {self.base_model_name}")
        
        BaseModel = base_models[self.base_model_name]
        
        # Créer le modèle de base
        base_model = BaseModel(
            input_shape=self.img_size + (3,),
            include_top=False,
            weights='imagenet'
        )
        
        # Construire le modèle complet
        inputs = Input(shape=self.img_size + (3,))
        
        # Couches de base (gelées initialement)
        x = base_model(inputs, training=False)
        
        # Couches de classification avancées
        x = GlobalAveragePooling2D(name='global_avg_pool')(x)
        x = BatchNormalization(name='batch_norm_1')(x)
        x = Dropout(0.3, name='dropout_1')(x)
        
        # Couche dense intermédiaire
        x = Dense(512, activation='relu', 
                 kernel_regularizer=l2(0.001), 
                 name='dense_1')(x)
        x = BatchNormalization(name='batch_norm_2')(x)
        x = Dropout(0.5, name='dropout_2')(x)
        
        # Couche dense finale
        x = Dense(256, activation='relu', 
                 kernel_regularizer=l2(0.001), 
                 name='dense_2')(x)
        x = BatchNormalization(name='batch_norm_3')(x)
        x = Dropout(0.3, name='dropout_3')(x)
        
        # Couche de sortie
        outputs = Dense(num_classes, activation='softmax', 
                       name='predictions')(x)
        
        # Créer le modèle
        model = Model(inputs, outputs, name=f'plant_disease_{self.base_model_name}')
        
        # Stocker le modèle de base pour le fine-tuning
        self.base_model = base_model
        
        return model
    
    def compile_model(self, model, learning_rate=0.001, stage='initial'):
        """
        Compile le modèle avec les métriques avancées
        """
        print(f"⚙️ Compilation du modèle (stage: {stage})...")
        
        # Optimizer adaptatif selon le stage
        if stage == 'initial':
            optimizer = Adam(learning_rate=learning_rate)
        else:  # fine-tuning
            optimizer = Adam(learning_rate=learning_rate/10)
        
        # Métriques avancées
        metrics = [
            'accuracy',
            TopKCategoricalAccuracy(k=3, name='top_3_accuracy'),
            Precision(name='precision'),
            Recall(name='recall')
        ]
        
        model.compile(
            optimizer=optimizer,
            loss='categorical_crossentropy',
            metrics=metrics
        )
        
        return model
    
    def create_callbacks(self, stage='initial'):
        """
        Crée les callbacks optimisés pour l'entraînement
        """
        callbacks = []
        
        # EarlyStopping
        early_stopping = EarlyStopping(
            monitor='val_loss',
            patience=15 if stage == 'initial' else 20,
            restore_best_weights=True,
            verbose=1
        )
        callbacks.append(early_stopping)
        
        # ReduceLROnPlateau
        reduce_lr = ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.2,
            patience=8 if stage == 'initial' else 10,
            min_lr=1e-8,
            verbose=1
        )
        callbacks.append(reduce_lr)
        
        # ModelCheckpoint
        model_path = self.session_dir / f'best_model_{stage}.h5'
        checkpoint = ModelCheckpoint(
            filepath=str(model_path),
            monitor='val_accuracy',
            save_best_only=True,
            save_weights_only=False,
            mode='max',
            verbose=1
        )
        callbacks.append(checkpoint)
        
        # TensorBoard
        tensorboard = TensorBoard(
            log_dir=str(self.logs_dir / f'tensorboard_{stage}'),
            histogram_freq=1,
            write_graph=True,
            write_images=True,
            update_freq='epoch'
        )
        callbacks.append(tensorboard)
        
        # CSVLogger
        csv_logger = CSVLogger(
            str(self.session_dir / f'training_log_{stage}.csv'),
            append=True
        )
        callbacks.append(csv_logger)
        
        return callbacks
    
    def train_stage_1(self, train_data, val_data, epochs=30):
        """
        Première phase d'entraînement avec base model gelé
        """
        print("\n🚀 PHASE 1: Entraînement initial (base model gelé)")
        print("="*60)
        
        # Créer le modèle
        if self.num_classes is None:
            self.num_classes = train_data.num_classes
        
        self.model = self.create_advanced_model(self.num_classes)
        
        # Geler le modèle de base
        self.base_model.trainable = False
        
        # Compiler
        self.model = self.compile_model(self.model, learning_rate=0.001, stage='initial')
        
        # Afficher l'architecture
        print("\n📋 Architecture du modèle:")
        self.model.summary()
        
        # Callbacks
        callbacks = self.create_callbacks(stage='initial')
        
        # Entraînement
        print(f"\n🏃 Début de l'entraînement (Phase 1) - {epochs} epochs")
        history_1 = self.model.fit(
            train_data,
            validation_data=val_data,
            epochs=epochs,
            class_weight=self.class_weights,
            callbacks=callbacks,
            verbose=1
        )
        
        return history_1
    
    def train_stage_2(self, train_data, val_data, epochs=20):
        """
        Deuxième phase d'entraînement avec fine-tuning
        """
        print("\n🔥 PHASE 2: Fine-tuning (dégelage partiel)")
        print("="*60)
        
        # Dégeler les dernières couches du modèle de base
        self.base_model.trainable = True
        
        # Geler seulement les premières couches
        fine_tune_at = len(self.base_model.layers) // 2
        
        for layer in self.base_model.layers[:fine_tune_at]:
            layer.trainable = False
        
        print(f"🔓 Couches dégelées: {len(self.base_model.layers) - fine_tune_at}/{len(self.base_model.layers)}")
        
        # Recompiler avec un learning rate plus faible
        self.model = self.compile_model(self.model, learning_rate=0.0001, stage='fine_tuning')
        
        # Callbacks
        callbacks = self.create_callbacks(stage='fine_tuning')
        
        # Entraînement
        print(f"\n🏃 Début du fine-tuning (Phase 2) - {epochs} epochs")
        history_2 = self.model.fit(
            train_data,
            validation_data=val_data,
            epochs=epochs,
            class_weight=self.class_weights,
            callbacks=callbacks,
            verbose=1
        )
        
        return history_2
    
    def evaluate_model(self, test_data):
        """
        Évaluation complète du modèle
        """
        print("\n📊 ÉVALUATION COMPLÈTE DU MODÈLE")
        print("="*50)
        
        # Évaluation de base
        test_loss, test_accuracy, test_top3_acc, test_precision, test_recall = self.model.evaluate(
            test_data, verbose=1
        )
        
        # Calcul F1-score
        f1_score = 2 * (test_precision * test_recall) / (test_precision + test_recall)
        
        # Affichage des résultats
        results = {
            'test_loss': test_loss,
            'test_accuracy': test_accuracy,
            'test_top3_accuracy': test_top3_acc,
            'test_precision': test_precision,
            'test_recall': test_recall,
            'test_f1_score': f1_score
        }
        
        print(f"\n🎯 RÉSULTATS FINAUX:")
        print(f"   • Accuracy: {test_accuracy:.4f}")
        print(f"   • Top-3 Accuracy: {test_top3_acc:.4f}")
        print(f"   • Precision: {test_precision:.4f}")
        print(f"   • Recall: {test_recall:.4f}")
        print(f"   • F1-Score: {f1_score:.4f}")
        print(f"   • Loss: {test_loss:.4f}")
        
        # Sauvegarde des résultats
        with open(self.session_dir / 'final_results.json', 'w') as f:
            json.dump(results, f, indent=2)
        
        return results
    
    def generate_detailed_report(self, test_data):
        """
        Génère un rapport détaillé avec matrice de confusion
        """
        print("\n📋 Génération du rapport détaillé...")
        
        # Prédictions
        predictions = self.model.predict(test_data, verbose=1)
        y_pred = np.argmax(predictions, axis=1)
        
        # Vraies étiquettes
        y_true = test_data.classes
        
        # Noms des classes
        class_names = list(test_data.class_indices.keys())
        
        # Rapport de classification
        report = classification_report(
            y_true, y_pred, 
            target_names=class_names,
            output_dict=True
        )
        
        # Matrice de confusion
        cm = confusion_matrix(y_true, y_pred)
        
        # Visualisation de la matrice de confusion
        plt.figure(figsize=(12, 10))
        sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',
                   xticklabels=class_names, yticklabels=class_names)
        plt.title('Matrice de Confusion')
        plt.ylabel('Vraies étiquettes')
        plt.xlabel('Prédictions')
        plt.xticks(rotation=45)
        plt.yticks(rotation=0)
        plt.tight_layout()
        plt.savefig(self.session_dir / 'confusion_matrix.png', dpi=300, bbox_inches='tight')
        plt.close()
        
        # Sauvegarder le rapport
        with open(self.session_dir / 'classification_report.json', 'w') as f:
            json.dump(report, f, indent=2)
        
        print(f"✅ Rapport détaillé sauvegardé dans {self.session_dir}")
        
        return report, cm
    
    def plot_training_history(self, history_1, history_2=None):
        """
        Visualise l'historique d'entraînement
        """
        print("\n📈 Création des graphiques d'entraînement...")
        
        # Combiner les historiques si il y a 2 phases
        if history_2 is not None:
            # Combiner les historiques
            combined_history = {}
            for key in history_1.history.keys():
                combined_history[key] = history_1.history[key] + history_2.history[key]
            
            # Marquer la transition
            phase1_epochs = len(history_1.history['loss'])
        else:
            combined_history = history_1.history
            phase1_epochs = None
        
        # Créer les graphiques
        fig, axes = plt.subplots(2, 2, figsize=(15, 12))
        
        # Accuracy
        axes[0, 0].plot(combined_history['accuracy'], label='Train Accuracy', color='blue')
        axes[0, 0].plot(combined_history['val_accuracy'], label='Val Accuracy', color='red')
        if phase1_epochs:
            axes[0, 0].axvline(x=phase1_epochs-1, color='green', linestyle='--', alpha=0.7, label='Fine-tuning start')
        axes[0, 0].set_title('Précision du modèle')
        axes[0, 0].set_xlabel('Époque')
        axes[0, 0].set_ylabel('Accuracy')
        axes[0, 0].legend()
        axes[0, 0].grid(True, alpha=0.3)
        
        # Loss
        axes[0, 1].plot(combined_history['loss'], label='Train Loss', color='blue')
        axes[0, 1].plot(combined_history['val_loss'], label='Val Loss', color='red')
        if phase1_epochs:
            axes[0, 1].axvline(x=phase1_epochs-1, color='green', linestyle='--', alpha=0.7, label='Fine-tuning start')
        axes[0, 1].set_title('Perte du modèle')
        axes[0, 1].set_xlabel('Époque')
        axes[0, 1].set_ylabel('Loss')
        axes[0, 1].legend()
        axes[0, 1].grid(True, alpha=0.3)
        
        # Precision
        axes[1, 0].plot(combined_history['precision'], label='Train Precision', color='blue')
        axes[1, 0].plot(combined_history['val_precision'], label='Val Precision', color='red')
        if phase1_epochs:
            axes[1, 0].axvline(x=phase1_epochs-1, color='green', linestyle='--', alpha=0.7, label='Fine-tuning start')
        axes[1, 0].set_title('Précision du modèle')
        axes[1, 0].set_xlabel('Époque')
        axes[1, 0].set_ylabel('Precision')
        axes[1, 0].legend()
        axes[1, 0].grid(True, alpha=0.3)
        
        # Recall
        axes[1, 1].plot(combined_history['recall'], label='Train Recall', color='blue')
        axes[1, 1].plot(combined_history['val_recall'], label='Val Recall', color='red')
        if phase1_epochs:
            axes[1, 1].axvline(x=phase1_epochs-1, color='green', linestyle='--', alpha=0.7, label='Fine-tuning start')
        axes[1, 1].set_title('Rappel du modèle')
        axes[1, 1].set_xlabel('Époque')
        axes[1, 1].set_ylabel('Recall')
        axes[1, 1].legend()
        axes[1, 1].grid(True, alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(self.session_dir / 'training_history.png', dpi=300, bbox_inches='tight')
        plt.close()
        
        print(f"✅ Graphiques sauvegardés dans {self.session_dir}")
    
    def save_final_model(self):
        """
        Sauvegarde le modèle final avec métadonnées
        """
        print("\n💾 Sauvegarde du modèle final...")
        
        # Sauvegarder le modèle
        model_path = self.model_dir / 'plant_disease_model_optimized.h5'
        self.model.save(model_path)
        
        # Sauvegarder les métadonnées
        metadata = {
            'model_architecture': self.base_model_name,
            'img_size': self.img_size,
            'num_classes': self.num_classes,
            'class_indices': self.class_indices,
            'training_timestamp': datetime.datetime.now().isoformat(),
            'model_path': str(model_path)
        }
        
        with open(self.model_dir / 'model_metadata.json', 'w') as f:
            json.dump(metadata, f, indent=2)
        
        print(f"✅ Modèle sauvegardé: {model_path}")
        print(f"✅ Métadonnées sauvegardées: {self.model_dir / 'model_metadata.json'}")
        
        return model_path
    
    def train_complete(self, train_data, val_data, test_data, 
                      epochs_phase1=30, epochs_phase2=20):
        """
        Entraînement complet avec les deux phases
        """
        print("\n🎯 DÉBUT DE L'ENTRAÎNEMENT COMPLET")
        print("="*70)
        
        # Stocker les informations des classes
        self.class_indices = train_data.class_indices
        self.class_weights = getattr(train_data, 'class_weights', None)
        
        # Phase 1: Entraînement initial
        history_1 = self.train_stage_1(train_data, val_data, epochs_phase1)
        
        # Phase 2: Fine-tuning
        history_2 = self.train_stage_2(train_data, val_data, epochs_phase2)
        
        # Évaluation finale
        results = self.evaluate_model(test_data)
        
        # Génération du rapport détaillé
        report, cm = self.generate_detailed_report(test_data)
        
        # Visualisation de l'historique
        self.plot_training_history(history_1, history_2)
        
        # Sauvegarde du modèle final
        model_path = self.save_final_model()
        
        print(f"\n🎉 ENTRAÎNEMENT TERMINÉ AVEC SUCCÈS!")
        print(f"📁 Résultats dans: {self.session_dir}")
        print(f"🤖 Modèle sauvegardé: {model_path}")
        
        return self.model, results, (history_1, history_2)

# Fonction principale pour utilisation directe
def train_plant_disease_model(base_model='mobilenetv2', 
                            img_size=(224, 224), 
                            batch_size=32,
                            epochs_phase1=30, 
                            epochs_phase2=20):
    """
    Fonction principale pour entraîner le modèle
    """
    # Importer le préprocessing
    from preprocess import load_all_data
    
    # Charger les données
    print("📊 Chargement des données...")
    train_data, val_data, test_data, class_weights = load_all_data(
        img_size=img_size, batch_size=batch_size
    )
    
    # Créer le trainer
    trainer = PlantDiseaseTrainer(
        img_size=img_size,
        batch_size=batch_size,
        base_model_name=base_model
    )
    
    # Ajouter les class_weights
    trainer.class_weights = class_weights
    
    # Entraîner le modèle
    model, results, history = trainer.train_complete(
        train_data, val_data, test_data,
        epochs_phase1, epochs_phase2
    )
    
    return model, results, history

# Exécution directe
if __name__ == "__main__":
    # Paramètres d'entraînement
    CONFIG = {
        'base_model': 'mobilenetv2',  # 'mobilenetv2', 'efficientnetb0', 'resnet50v2'
        'img_size': (224, 224),
        'batch_size': 32,
        'epochs_phase1': 30,
        'epochs_phase2': 20
    }
    
    print("🚀 Lancement de l'entraînement optimisé...")
    print(f"⚙️ Configuration: {CONFIG}")
    
    # Entraîner le modèle
    model, results, history = train_plant_disease_model(**CONFIG)
    
    print("\n🎊 Entraînement terminé avec succès!")
    print(f"🏆 Accuracy finale: {results['test_accuracy']:.4f}")
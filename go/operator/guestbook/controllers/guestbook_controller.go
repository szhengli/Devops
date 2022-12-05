/*
Copyright 2022.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package controllers

import (
	"context"
	"fmt"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/meta"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/client-go/tools/record"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	"time"

	//v1 "k8s.io/client-go/applyconfigurations/meta/v1"
	apierrors "k8s.io/apimachinery/pkg/api/errors"
	webappv1 "my.domain/guestbook/api/v1"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/log"
)

// GuestbookReconciler reconciles a Guestbook object
type GuestbookReconciler struct {
	client.Client
	Scheme   *runtime.Scheme
	Recorder record.EventRecorder
}

const cleanFinalizer = "webapp.my.domain/clean"

var (
	jobOwnerKey = ".metadata.controller"
)

//+kubebuilder:rbac:groups=webapp.my.domain,resources=guestbooks,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=webapp.my.domain,resources=guestbooks/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=webapp.my.domain,resources=guestbooks/finalizers,verbs=update

// Reconcile is part of the main kubernetes reconciliation loop which aims to
// move the current state of the cluster closer to the desired state.
// TODO(user): Modify the Reconcile function to compare the state specified by
// the Guestbook object against the actual cluster state, and then
// perform operations to make the cluster state reflect the state specified by
// the user.
//
// For more details, check Reconcile and its Result here:
// - https://pkg.go.dev/sigs.k8s.io/controller-runtime@v0.13.0/pkg/reconcile
func (r *GuestbookReconciler) BuildDeploy(guestbook *webappv1.Guestbook) (*appsv1.Deployment, error) {
	size := guestbook.Spec.Size
	image := guestbook.Spec.Image

	deploy := &appsv1.Deployment{
		ObjectMeta: metav1.ObjectMeta{
			Annotations: map[string]string{
				"configs": guestbook.Spec.Configs,
			},
			Name:      guestbook.Name,
			Namespace: guestbook.Namespace,
		},
		Spec: appsv1.DeploymentSpec{
			Replicas: &size,
			Selector: &metav1.LabelSelector{
				MatchLabels: map[string]string{
					"app": guestbook.Name,
				},
			},
			Template: corev1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{
					Labels: map[string]string{
						"app": guestbook.Name,
					},
				},
				Spec: corev1.PodSpec{
					Containers: []corev1.Container{
						{
							Image:           image,
							Name:            guestbook.Name,
							ImagePullPolicy: corev1.PullIfNotPresent,
							Ports: []corev1.ContainerPort{
								{
									ContainerPort: 80,
									Name:          "guestport",
								},
							},
						},
					},
				},
			},
		},
	}

	if err := ctrl.SetControllerReference(guestbook, deploy, r.Scheme); err != nil {
		return nil, err
	}
	return deploy, nil
}

func (r *GuestbookReconciler) doCleanFinalizer(guestbook *webappv1.Guestbook) {
	fmt.Println("################# doing cleaning up  ##############################")
	r.Recorder.Event(guestbook, "warning", "deleting", fmt.Sprintf(
		"Custom Resource %s is being deleted from the namespace", guestbook.Name,
	))
}

func (r *GuestbookReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	klog := log.FromContext(ctx)

	fmt.Println("---------executing reconcile")
	var guestbook webappv1.Guestbook
	// TODO(user): your logic here

	if err := r.Get(ctx, req.NamespacedName, &guestbook); err != nil {
		if apierrors.IsNotFound(err) {
			klog.Info("The Guestbook object  has be deleted.")
			return ctrl.Result{}, nil
		}

		klog.Error(err, "Unable to fetch the object------")
		return ctrl.Result{}, err
	}

	if guestbook.Status.Conditions == nil || len(guestbook.Status.Conditions) == 0 {
		fmt.Println("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
		meta.SetStatusCondition(&guestbook.Status.Conditions, metav1.Condition{
			Type: "Available", Status: metav1.ConditionUnknown, Reason: "Reconciling",
			Message: "Starting reconciling",
		})
		if err := r.Status().Update(ctx, &guestbook); err != nil {
			klog.Error(err, "fail to update status")
			return ctrl.Result{}, err
		}
		if err := r.Get(ctx, req.NamespacedName, &guestbook); err != nil {
			klog.Error(err, "Unable to Re-fetch the object----+++--")
			return ctrl.Result{}, client.IgnoreNotFound(err)
		}
	}

	//****************************************************   start to deal with finalizer

	if guestbook.GetDeletionTimestamp() != nil {

		klog.Info("Perform finalizer operation for deletion")
		meta.SetStatusCondition(&guestbook.Status.Conditions, metav1.Condition{
			Type:   "beginguestbook",
			Status: metav1.ConditionUnknown, Reason: "Finalizing",
			Message: fmt.Sprintf("Performing finalizing"),
		})
		if err := r.Status().Update(ctx, &guestbook); err != nil {
			klog.Error(err, "fail to update status")
			return ctrl.Result{}, err
		}

		if err := r.Get(ctx, req.NamespacedName, &guestbook); err != nil {
			klog.Error(err, "fail to re-fetch guestbook")
			return ctrl.Result{}, err
		}

		meta.SetStatusCondition(&guestbook.Status.Conditions, metav1.Condition{
			Type:   "begindeleting",
			Status: metav1.ConditionTrue, Reason: "finalizing",
			Message: fmt.Sprintf("Finalizer operations for custom resource %s name were successfully accomplished\", guestbook.Name)", guestbook.Name),
		})

		if err := r.Status().Update(ctx, &guestbook); err != nil {
			klog.Error(err, "fail to update guestbook status")
			return ctrl.Result{}, err
		}

		if err := r.Get(ctx, req.NamespacedName, &guestbook); err != nil {
			klog.Error(err, "fail to re-fetch guestbook")
			return ctrl.Result{}, err
		}

		klog.Info("Removing the clean finalize successfully")
		if ok := controllerutil.RemoveFinalizer(&guestbook, cleanFinalizer); !ok {
			klog.Info("fail to remove clean finalizer")
			return ctrl.Result{}, nil
		}
		if err := r.Update(ctx, &guestbook); err != nil {
			klog.Error(err, "fail to remove finalizer")
			return ctrl.Result{Requeue: true}, err
		}

		return ctrl.Result{}, nil
	}

	//------------------------------------------------  complete  deal with finalizer

	found := &appsv1.Deployment{}

	err := r.Get(ctx, req.NamespacedName, found)

	if err != nil && apierrors.IsNotFound(err) {
		klog.Info("not find the deployment , will create a new one -----")
		deploy, err := r.BuildDeploy(&guestbook)
		if err != nil {
			klog.Error(err, "Fail to define new Deployment resource")
			meta.SetStatusCondition(&guestbook.Status.Conditions, metav1.Condition{
				Type: "Available", Status: metav1.ConditionFalse,
				Message: fmt.Sprintf("Failed to create Deployment for the custom resource (%s): (%s)", guestbook.Name, err)})
			if err := r.Status().Update(ctx, &guestbook); err != nil {
				klog.Error(err, "Failed to update Memcached status")
				return ctrl.Result{}, err
			}

			return ctrl.Result{}, err
		}
		if err := r.Create(ctx, deploy); err != nil {
			return ctrl.Result{}, err
		}
		klog.V(1).Info("created the deployment ------------!!!!!!")
		return ctrl.Result{RequeueAfter: time.Minute}, nil
	} else if err != nil {
		klog.Error(err, "fail to get deployment")
		return ctrl.Result{}, err
	}

	if *found.Spec.Replicas != guestbook.Spec.Size || found.Spec.Template.Spec.Containers[0].Image != guestbook.Spec.Image {
		found.Spec.Replicas = &guestbook.Spec.Size
		found.Spec.Template.Spec.Containers[0].Image = guestbook.Spec.Image

		if err = r.Update(ctx, found); err != nil {
			klog.Error(err, "fail to update ")
			if err := r.Get(ctx, req.NamespacedName, &guestbook); err != nil {
				klog.Error(err, "Fail to re-fetch guestbook")
				return ctrl.Result{}, err
			}
			meta.SetStatusCondition(&guestbook.Status.Conditions, metav1.Condition{
				Type: "Available", Status: metav1.ConditionFalse, Reason: "updating error",
				Message: fmt.Sprintf("Failed to update the size for the custom resource (%s): (%s)", guestbook.Name, err)})
			if err := r.Status().Update(ctx, &guestbook); err != nil {
				klog.Error(err, "Failed to update Guestbook status")
				return ctrl.Result{}, err
			}

			return ctrl.Result{}, err
		}

		klog.V(1).Info("updated the deployment ------------######")
		return ctrl.Result{Requeue: true}, nil
	}

	meta.SetStatusCondition(&guestbook.Status.Conditions, metav1.Condition{
		Type:   "available",
		Status: metav1.ConditionTrue, Reason: "reconciling",
		Message: fmt.Sprintf("Deployment for the custom resources replicas created successfully"),
	})

	if err := r.Status().Update(ctx, &guestbook); err != nil {
		klog.Error(err, "Fail to upddate Guestbook status ")
		return ctrl.Result{}, err
	}

	return ctrl.Result{}, nil
}

// SetupWithManager sets up the controller with the Manager.
func (r *GuestbookReconciler) SetupWithManager(mgr ctrl.Manager) error {

	if err := mgr.GetFieldIndexer().IndexField(context.Background(), &appsv1.Deployment{}, jobOwnerKey, func(rawObj client.Object) []string {
		// grab the job object, extract the owner...
		deploy := rawObj.(*appsv1.Deployment)
		owner := metav1.GetControllerOf(deploy)
		if owner == nil {
			return nil
		}
		// ...make sure it's a CronJob...
		if owner.Kind != "Guestbook" {
			return nil
		}

		// ...and if so, return it
		return []string{owner.Name}
	}); err != nil {
		return err
	}

	return ctrl.NewControllerManagedBy(mgr).
		For(&webappv1.Guestbook{}).
		Owns(&appsv1.Deployment{}).
		Complete(r)
}
